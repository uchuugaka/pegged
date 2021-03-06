//
//  Generated by pegged $Version
//  Fork: https://github.com/dparnell/pegged
//  File is auto-generated. Do not modify.
//

//!$OtherClasses
//!$OtherProtocols

/*!
 @abstract The ParserClass public interface
 */
@interface ParserClass : NSObject

//!$Properties


#pragma mark - Error handling

/*!
 @abstract The last error state of the parser.
 @discussion ParserClassErrorStringLocationKey, ParserClassErrorStringLengthKey provides the index and length of the errorneous string (NSNumber), ParserClassErrorStringKey the errorneous string. ParserClassErrorTypeKey contains a grammar-dependent error key. The localized description of the error will be generated from the string file of the ParserClass, whereas the ParserClassErrorTypeKey will be used as localization string key.
 */
@property (readonly) NSError *lastError;

/*!
 @abstract The location of the substring that caused the last error
 */
extern NSString *ParserClassErrorStringLocationKey;

/*!
 @abstract The length of the substring that caused the last error
 */
extern NSString *ParserClassErrorStringLengthKey;

/*!
 @abstract The string that caused the error.
 @discussion Use ParserClassErrorStringLocationKey, ParserClassErrorStringLengthKey to derive the errorneous substring.
 */
extern NSString *ParserClassErrorStringKey;

/*!
 @abstract A grammar dependent error type.
 @discussion Will be used to generate a NSLocalizedErrorDescriptionKey by using this error type as key in the strng file of ParserClass.
 */
extern NSString *ParserClassErrorTypeKey;


#pragma mark - Parsing methods

/*!
 @abstract Parses the given string and passes the return value of the start rule as output argument.
 @discussion Returns YES on match.
 */
- (BOOL)parseString:(NSString *)string result:(id *)result;

@end



/*!
 @abstract Methods available to parser actions
 */
@interface ParserClass (ParserActionHelper)


#pragma mark - Parser state

/*!
 @abstract The start index of the current capture
 */
@property (readonly) NSUInteger captureStart;

/*!
 @abstract The end index of the current capture
 */
@property (readonly) NSUInteger captureEnd;

/*!
 @abstract The currently parsed string
 */
@property (readonly) NSString* string;


#pragma mark - Action helpers

/*!
 @abstract Provides a result for the current rule
 */
- (void)pushResult:(id)result;

/*!
 @abstract Accesses the next result of a sub-rule
 */
- (id)nextResult;

/*!
 @abstract Accesses the next result of a sub-rule, if a certain result count matches.
 @discussion Returns nil otherwise.
 */
- (id)nextResultIfCount:(NSInteger)count;

/*!
 @abstract Accesses the next result of a sub-rule. Returns nil, if none is available
 */
- (id)nextResultOrNil;

/*!
 @abstract Accesses the result of a sub-rule with a certain index
 */
- (id)resultAtIndex:(NSInteger)index;

/*!
 @abstract Accesses the result of a sub-rule with a certain index. If the result does not exist, nil is returned.
 */
- (id)resultAtIndexIfAny:(NSInteger)index;

/*!
 @abstract Provies all sub-rule results as array.
 */
- (NSArray *)allResults;

/*!
 @abstract Provides the count of results.
 */
- (NSInteger)resultCount;

/*!
 @abstract Provides the range of the current action
 */
- (NSRange)rangeForCurrentAction;

@end



/*!
 @abstract A protocol that is used to annotate diagnostic informations on parser results
*/
@protocol ParserClassDiagnostics <NSObject>

@optional

/*!
 @abstract Sets the string and range a style statement was parsed from.
 */
- (void)setSourceString:(NSString *)string range:(NSRange)range;

@end
