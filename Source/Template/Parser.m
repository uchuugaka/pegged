//
//  Generated by pegged $Version
//  Fork: https://github.com/hydrixos/pegged
//  File is auto-generated. Do not modify.
//

#import "Parser.h"
//!$Imports

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define ParserClassLocalizedString(__key)	(NSLocalizedStringFromTableInBundle((__key), NSStringFromClass(self.class), [NSBundle bundleForClass: self.class], nil))

NSString *ParserClassErrorStringLocationKey		= @"ParserClassErrorStringLocation";
NSString *ParserClassErrorStringLengthKey		= @"ParserClassErrorStringLength";
NSString *ParserClassErrorStringKey				= @"ParserClassErrorString";
NSString *ParserClassErrorTypeKey				= @"ParserClassErrorType";

#pragma mark - Internal types

// A block implementing a certain parsing rule
typedef BOOL (^ParserClassRule)(ParserClass *parser, NSInteger startIndex, NSInteger *localCaptures);

// A block implementing a certain parser action
typedef id (^ParserClassAction)(ParserClass *self, NSString *text, NSString **errorCode);


/*!
 @abstract Internally used class for storing captured text results for actions.
 */
@interface ParserClassCapture : NSObject

// The position index used for text capturing
@property NSUInteger begin;
@property NSUInteger end;

// The parsed ranged used for this capture
@property NSRange parsedRange;

// The action associated with a capture
@property (copy) ParserClassAction action;

// The count of captured results available to an action
@property NSInteger capturedResultsCount;

// All results captured by the action
@property NSArray *allResults;

// The index of the next result to be read by the action
@property NSInteger nextResultIndex;

@end

@implementation ParserClassCapture
@end


/*!
 @abstract Internal parser methods
 */
@interface ParserClass ()
{
	// The last error state
	NSError *_lastError;
	
	// The rule set used by the parser
	NSMutableDictionary *_rules;
	
	// The current string position
	NSUInteger _index;
	NSUInteger _limit;
		
	// Specifies whether the parser is currently capturing
	BOOL _capturing;
	
	// All currently matched captures
	NSMutableArray *_captures;
	
	// The results of the last actions
	NSMutableArray *_actionResults;

	// The capture of the currently performed action
	ParserClassCapture *_currentCapture;
	
	// The context used to parameterize parsing.
	NSDictionary *_context;
}

// Public parser state information
@property (readonly) NSUInteger captureStart;
@property (readonly) NSUInteger captureEnd;
@property (readonly) NSString* string;

@property (readonly) NSUInteger index;

@end


@implementation ParserClass

- (id)init
{
    self = [super init];
    
    if (self)
    {
        _rules = [NSMutableDictionary new];

//!$ParserDeclarations
    }
    
    return self;
}


#pragma mark - String matching

- (void)beginCapture
{
    if (_capturing) _captureStart = _index;
}

- (void)endCapture
{
    if (_capturing) _captureEnd = _index;
}

- (BOOL)invertWithCaptures:(NSInteger *)localCaptures startIndex:(NSInteger)startIndex block:(ParserClassRule)rule
{
	NSInteger temporaryCaptures = *localCaptures;
	
	// We are in an error state. Just stop.
	if (_lastError)
		return NO;
	
    BOOL matched = ![self matchOneWithCaptures:&temporaryCaptures startIndex:startIndex block:rule];
	if (matched)
		*localCaptures = temporaryCaptures;
	
	return matched;
}

- (BOOL)lookAheadWithCaptures:(NSInteger *)localCaptures startIndex:(NSInteger)startIndex block:(ParserClassRule)rule
{
    NSUInteger index=_index;

	// We are in an error state. Just stop.
	if (_lastError)
		return NO;
	
    BOOL capturing = _capturing;
    _capturing = NO;
	
	NSInteger temporaryCaptures = *localCaptures;
	
    BOOL matched = rule(self, startIndex, &temporaryCaptures);
    _capturing = capturing;
    _index=index;
	_lastError = nil;
	
    return matched;
}

- (BOOL)matchDot
{
    if (_index >= _limit)
		return NO;
	
    ++_index;
    return YES;
}

- (BOOL)matchOneWithCaptures:(NSInteger *)localCaptures startIndex:(NSInteger)startIndex block:(ParserClassRule)rule
{
	// We are in an error state. Just stop.
	if (_lastError)
		return NO;
	
    NSUInteger index=_index, captureCount=[_captures count];
	NSInteger temporaryCaptures = *localCaptures;
	
	// Try to match
    if (rule(self, startIndex, &temporaryCaptures)) {
		*localCaptures = temporaryCaptures;
        return YES;
	}
	
	// Restore old state
    _index=index;
	
    if ([_captures count] > captureCount) {
        NSRange rangeToRemove = NSMakeRange(captureCount, [_captures count]-captureCount);
        [_captures removeObjectsInRange:rangeToRemove];
    }
	
    return NO;
}

- (BOOL)matchManyWithCaptures:(NSInteger *)localCaptures startIndex:(NSInteger)startIndex block:(ParserClassRule)rule
{
	// We are in an error state. Just stop.
	if (_lastError)
		return NO;
	
	// We need at least one match
    if (![self matchOneWithCaptures:localCaptures startIndex:startIndex block:rule])
        return NO;
	
	// Match others
	NSInteger lastIndex = _index;
	
    while ([self matchOneWithCaptures:localCaptures startIndex:startIndex block:rule]) {
		// The match did not consume any string, but matched. It should be something like (.*)*. So we can stop to prevent an infinite loop.
		if (_index == lastIndex)
			break;
		
		lastIndex = _index;
	}
    
	return YES;
}

- (BOOL)matchRule:(NSString *)ruleName startIndex:(NSInteger)startIndex asserted:(BOOL)asserted
{
    NSArray *rules = [_rules objectForKey: ruleName];
	NSInteger lastIndex = _index;
	
	// We are in an error state. Just stop.
	if (_lastError)
		return NO;
    
	if (![rules count])
        NSLog(@"Couldn't find rule name \"%@\".", ruleName);
	
	for (ParserClassRule rule in rules) {
		NSInteger localCaptures = 0;
		
		if ([self matchOneWithCaptures:&localCaptures startIndex:_index block:rule])
			return YES;
	}

	if (asserted)
		[self setErrorWithMessage: [NSString stringWithFormat: @"Unmatched%@", ruleName] location:lastIndex length:(_index - lastIndex)];
	
    return NO;
}

- (BOOL)matchString:(char *)literal startIndex:(NSInteger)startIndex asserted:(BOOL)asserted
{
	NSInteger saved = _index;
	
	while (*literal) {
		if ((_index >= _limit) || ([_string characterAtIndex: _index] != *literal)) {
			_index = saved;
			
			if (asserted)
				[self setErrorWithMessage: [NSString stringWithFormat: @"Missing:%s", literal] location:saved length:(_index - saved + 1)];
			
			return NO;
		}
		++literal;
		++_index;
	}

    return YES;
}

- (BOOL)matchClass:(unsigned char *)bits
{
    if (_index >= _limit) return NO;
	
    int c = [_string characterAtIndex:_index];
    
	if (bits[c >> 3] & (1 << (c & 7))) {
        ++_index;
        return YES;
    }
	
    return NO;
}

- (void)setErrorWithMessage:(NSString *)message location:(NSInteger)location length:(NSInteger)length
{
	if (length == 0) {
		if (location < _string.length) {
			length = 1;
		}
		else if (location > 0) {
			location --;
			length = 1;
		}
	}
		
	if (!_lastError)
		_lastError = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey: ParserClassLocalizedString(message), ParserClassErrorTypeKey: message, ParserClassErrorStringLocationKey: @(location), ParserClassErrorStringLengthKey: @(length), ParserClassErrorStringKey: [_string copy]}];
}

- (void)clearError
{
	_lastError = nil;
}


#pragma mark - Action handling

- (void)performActionUsingCaptures:(NSInteger)captures startIndex:(NSInteger)startIndex block:(ParserClassAction)action
{
    ParserClassCapture *capture = [ParserClassCapture new];
    
	capture.begin = _captureStart;
    capture.end = _captureEnd;
    
	capture.action = action;
	capture.parsedRange = NSMakeRange(startIndex, _index - startIndex);
	
	capture.capturedResultsCount = captures;

    [_captures addObject:capture];
}

- (void)pushResult:(id)result
{
	[_actionResults addObject: result];
}

- (id)nextResult
{
	return [_currentCapture.allResults objectAtIndex: _currentCapture.nextResultIndex++];
}

- (id)nextResultIfCount:(NSInteger)count
{
	if (_currentCapture.allResults.count == count)
		return [self nextResult];
	
	return nil;
}

- (id)nextResultOrNil
{
	if (_currentCapture.allResults.count <= _currentCapture.nextResultIndex)
		return nil;
	
	return [self nextResult];
}

- (id)resultAtIndex:(NSInteger)index
{
	return [_currentCapture.allResults objectAtIndex: index];
}

- (id)resultAtIndexIfAny:(NSInteger)index
{
	if (index > _currentCapture.allResults.count)
		return nil;
	
	return [self resultAtIndex: index];
}

- (NSInteger)resultCount
{
	return _currentCapture.capturedResultsCount;
}

- (NSArray *)allResults
{
	return _currentCapture.allResults ?: @[];
}

- (NSRange)rangeForCurrentAction
{
	return _currentCapture.parsedRange;
}


#pragma mark - Rule definitions

- (void)addRule:(ParserClassRule)rule withName:(NSString *)name
{
    NSMutableArray *rules = [_rules objectForKey:name];
    if (!rules) {
        rules = [NSMutableArray new];
        [_rules setObject:rules forKey:name];
    }
    
    [rules addObject:rule];
}

//!$ParserDefinitions


#pragma mark - Parsing methods

- (NSString *)yyText:(NSUInteger)begin to:(NSUInteger)end
{
    NSInteger len = end - begin;
    if (len <= 0)
        return @"";
    return [_string substringWithRange:NSMakeRange(begin, len)];
}

- (BOOL)parseString:(NSString *)string result:(id *)result
{
	// Prepare parser input
	_string = string;
	#ifdef __PEG_PARSER_CASE_INSENSITIVE__
		_string = [_string lowercaseString];
	#endif
		
    // Setup capturing limits
	_limit  = _string.length;
    _index  = 0;
	
	_captures = [NSMutableArray new];
	_actionResults = [NSMutableArray new];

	_captureStart= _captureEnd= _index;
    _capturing = YES;
    
	// Do string matching
    BOOL matched = [self matchRule: @"$StartRule" startIndex:_index asserted:YES];
    
	// Process actions
    if (matched) {
		for (ParserClassCapture *capture in _captures) {
			_currentCapture = capture;

			// Prepare results
			NSInteger resultsCount = _currentCapture.capturedResultsCount;
			NSRange resultsRange = NSMakeRange(_actionResults.count - resultsCount, resultsCount);
			
			if (resultsCount) {
				// Read all results
				capture.allResults = [_actionResults subarrayWithRange: resultsRange];
				capture.nextResultIndex = 0;
				
				// Remove results from stack
				[_actionResults removeObjectsInRange: resultsRange];
			}
			
			NSString *errorCode;
			
			id result = capture.action(self, [self yyText:capture.begin to:capture.end], &errorCode);
			
			// Handle errors if any
			if (errorCode) {
				[self setErrorWithMessage:errorCode location:capture.parsedRange.location length:capture.parsedRange.length];
				matched = NO;
				break;
			}
			
			// Push result
			if (result) {
				// Set parsing range for diagnostics
				if ([result respondsToSelector: @selector(setSourceString:range:)])
					[result setSourceString:_string range:capture.parsedRange];
				
				[self pushResult: result];
			}
		}
		
		// Provide final result if any
		if (matched && _actionResults.count)
			if (result) *result = _actionResults.lastObject;
	}
	
    // Cleanup parser
    _string = nil;
	_actionResults = nil;
	_context = nil;
	
	return matched;
}


#pragma mark - Helper methods

- (NSInteger)lineNumberForIndex:(NSInteger)index
{
	__block NSInteger line = 0;
	
	[_string enumerateSubstringsInRange:NSMakeRange(0, index >= _string.length ? _string.length-1 : index) options:NSStringEnumerationByLines|NSStringEnumerationSubstringNotRequired usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
		line ++;
	}];
	
	return line;
}

- (NSInteger)columnNumberForIndex:(NSInteger)index
{
	return index - [_string lineRangeForRange: NSMakeRange(index >= _string.length ? _string.length-1 : index, 1)].location;
}

- (NSString *)positionDescriptionForIndex:(NSInteger)index
{
	return [NSString stringWithFormat: @"line: %li, column: %li", [self lineNumberForIndex: index], [self columnNumberForIndex: index]];
}

@end
