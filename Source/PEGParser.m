//
//  Generated by pegged 0.3.8.
//

#import "PEGParser.h"

#import "Compiler.h"

@interface PEGParserCapture : NSObject
{
    NSUInteger _begin;
    NSUInteger _end;
    PEGParserAction _action;
}
@property (assign) NSUInteger begin;
@property (assign) NSUInteger end;
@property (copy) PEGParserAction action;
@end

@implementation PEGParserCapture
@synthesize begin = _begin;
@synthesize end = _end;
@synthesize action = _action;
- (void) dealloc
{
    [_action release];
    [super dealloc];
}
@end


@implementation PEGParser

@synthesize dataSource = _dataSource;

@synthesize captureStart = yybegin;
@synthesize captureEnd = yyend;
@synthesize compiler = _compiler;

//==================================================================================================
#pragma mark -
#pragma mark Rules
//==================================================================================================


#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef matchDEBUG
#define yyprintf(args)	{ fprintf args; fprintf(stderr," @ %s\n",[[_string substringFromIndex:_index] UTF8String]); }
#else
#define yyprintf(args)
#endif

- (BOOL) _refill
{
    if (!self.dataSource)
        return NO;

    NSString *nextString = [self.dataSource nextString];
    if (nextString)
    {
        nextString = [_string stringByAppendingString:nextString];
        [_string release];
        _string = [nextString retain];
    }
    _limit = [_string lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    yyprintf((stderr, "refill"));
    return YES;
}


- (void) beginCapture
{
    if (_capturing) yybegin = _index;
}


- (void) endCapture
{
    if (_capturing) yyend = _index;
}


- (BOOL) invert:(PEGParserRule)rule
{
    return ![self matchOne:rule];
}


- (BOOL) lookAhead:(PEGParserRule)rule
{
    NSUInteger index=_index;
    BOOL capturing = _capturing;
    _capturing = NO;
    BOOL matched = rule(self);
    _capturing = capturing;
    _index=index;
    return matched;
}


- (BOOL) matchDot
{
    if (_index >= _limit && ![self _refill]) return NO;
    ++_index;
    return YES;
}


- (BOOL) matchOne:(PEGParserRule)rule
{
    NSUInteger index=_index, captureCount=[_captures count];
    if (rule(self))
        return YES;
    _index=index;
    if ([_captures count] > captureCount)
    {
        NSRange rangeToRemove = NSMakeRange(captureCount, [_captures count]-captureCount);
        [_captures removeObjectsInRange:rangeToRemove];
    }
    return NO;
}


- (BOOL) matchMany:(PEGParserRule)rule
{
    if (![self matchOne:rule])
        return NO;
    while ([self matchOne:rule])
        ;
    return YES;
}


- (BOOL) matchRule:(NSString *)ruleName
{
    NSArray *rules = [_rules objectForKey:ruleName];
    if (![rules count])
        NSLog(@"Couldn't find rule name \"%@\".", ruleName);
    
    for (PEGParserRule rule in rules)
        if ([self matchOne:rule])
            return YES;
    return NO;
}


- (BOOL) matchString:(char *)s
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
#ifndef PEGPARSER_CASE_INSENSITIVE
    const char *cstring = [_string UTF8String];
#else
    const char *cstring = [[_string lowercaseString] UTF8String];
#endif
    int saved = _index;
    while (*s)
    {
        if (_index >= _limit && ![self _refill]) return NO;
        if (cstring[_index] != *s)
        {
            [pool drain];
            _index = saved;
            yyprintf((stderr, "  fail matchString"));
            return NO;
        }
        ++s;
        ++_index;
    }
    [pool drain];
    yyprintf((stderr, "  ok   matchString"));
    return YES;
}

- (BOOL) matchClass:(unsigned char *)bits
{
    if (_index >= _limit && ![self _refill]) return NO;
    int c = [_string characterAtIndex:_index];
    if (bits[c >> 3] & (1 << (c & 7)))
    {
        ++_index;
        yyprintf((stderr, "  ok   matchClass"));
        return YES;
    }
    yyprintf((stderr, "  fail matchClass"));
    return NO;
}

- (void) performAction:(PEGParserAction)action
{
    PEGParserCapture *capture = [PEGParserCapture new];
    capture.begin  = yybegin;
    capture.end    = yyend;
    capture.action = action;
    [_captures addObject:capture];
    [capture release];
}

- (NSString *) yyText:(int)begin to:(int)end
{
    int len = end - begin;
    if (len <= 0)
        return @"";
    return [_string substringWithRange:NSMakeRange(begin, len)];
}

- (void) yyDone
{
    for (PEGParserCapture *capture in _captures)
    {
        capture.action(self, [self yyText:capture.begin to:capture.end]);
    }
}

- (void) yyCommit
{
    NSString *newString = [_string substringFromIndex:_index];
    [_string release];
    _string = [newString retain];
    _limit -= _index;
    _index = 0;

    yybegin -= _index;
    yyend -= _index;
    [_captures removeAllObjects];
}

static PEGParserRule __AND = ^(PEGParser *parser){
    if (![parser matchString:"&"]) return NO;
    if (![parser matchRule:@"Spacing"]) return NO;
    return YES;
};

static PEGParserRule __Action = ^(PEGParser *parser){
    if (![parser matchString:"{"]) return NO;
    [parser beginCapture];
    [parser matchMany:^(PEGParser *parser){
    if (![parser matchClass:(unsigned char *)"\377\377\377\377\377\377\377\377\377\377\377\377\377\377\377\337\377\377\377\377\377\377\377\377\377\377\377\377\377\377\377\377"]) return NO;
    return YES;    }];
    [parser endCapture];
    if (![parser matchString:"}"]) return NO;
    if (![parser matchRule:@"Spacing"]) return NO;
    return YES;
};

static PEGParserRule __BEGIN = ^(PEGParser *parser){
    if (![parser matchString:"<"]) return NO;
    if (![parser matchRule:@"Spacing"]) return NO;
    return YES;
};

static PEGParserRule __CLOSE = ^(PEGParser *parser){
    if (![parser matchString:")"]) return NO;
    if (![parser matchRule:@"Spacing"]) return NO;
    return YES;
};

static PEGParserRule __Char = ^(PEGParser *parser){
    if (![parser matchOne:^(PEGParser *parser){
    if ([parser matchOne:^(PEGParser *parser){
    if (![parser matchString:"\\"]) return NO;
    if (![parser matchClass:(unsigned char *)"\000\000\000\000\204\000\000\000\000\000\000\070\000\100\024\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"]) return NO;
    return YES;    }]) return YES;
    if ([parser matchOne:^(PEGParser *parser){
    if (![parser matchString:"\\"]) return NO;
    if (![parser matchClass:(unsigned char *)"\000\000\000\000\000\000\007\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"]) return NO;
    if (![parser matchClass:(unsigned char *)"\000\000\000\000\000\000\377\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"]) return NO;
    if (![parser matchClass:(unsigned char *)"\000\000\000\000\000\000\377\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"]) return NO;
    return YES;    }]) return YES;
    if ([parser matchOne:^(PEGParser *parser){
    if (![parser matchString:"\\"]) return NO;
    if (![parser matchClass:(unsigned char *)"\000\000\000\000\000\000\377\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"]) return NO;
    [parser matchOne:^(PEGParser *parser){
    if (![parser matchClass:(unsigned char *)"\000\000\000\000\000\000\377\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"]) return NO;
    return YES;    }];
    return YES;    }]) return YES;
    if ([parser matchOne:^(PEGParser *parser){
    if (![parser matchString:"\\x"]) return NO;
    if (![parser matchClass:(unsigned char *)"\000\000\000\000\000\000\377\003\176\000\000\000\176\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"]) return NO;
    if (![parser matchClass:(unsigned char *)"\000\000\000\000\000\000\377\003\176\000\000\000\176\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"]) return NO;
    return YES;    }]) return YES;
    if ([parser matchOne:^(PEGParser *parser){
    if (![parser lookAhead:^(PEGParser *parser){
    if ([parser matchString:"\\"]) return NO;
    return YES;    }]) return NO;
    if (![parser matchDot]) return NO;
    return YES;    }]) return YES;
    return NO;    }]) return NO;
    return YES;
};

static PEGParserRule __Class = ^(PEGParser *parser){
    if (![parser matchString:"["]) return NO;
    [parser beginCapture];
    [parser matchMany:^(PEGParser *parser){
    if (![parser lookAhead:^(PEGParser *parser){
    if ([parser matchString:"]"]) return NO;
    return YES;    }]) return NO;
    if (![parser matchRule:@"Range"]) return NO;
    return YES;    }];
    [parser endCapture];
    if (![parser matchString:"]"]) return NO;
    if (![parser matchRule:@"Spacing"]) return NO;
    return YES;
};

static PEGParserRule __Code = ^(PEGParser *parser){
    if (![parser matchString:"{{"]) return NO;
    [parser beginCapture];
    [parser matchMany:^(PEGParser *parser){
    if (![parser matchClass:(unsigned char *)"\377\377\377\377\377\377\377\377\377\377\377\377\377\377\377\337\377\377\377\377\377\377\377\377\377\377\377\377\377\377\377\377"]) return NO;
    return YES;    }];
    [parser endCapture];
    if (![parser matchString:"}}"]) return NO;
    if (![parser matchRule:@"Spacing"]) return NO;
    return YES;
};

static PEGParserRule __Comment = ^(PEGParser *parser){
    if (![parser matchString:"#"]) return NO;
    [parser matchMany:^(PEGParser *parser){
    if (![parser lookAhead:^(PEGParser *parser){
    if ([parser matchRule:@"EndOfLine"]) return NO;
    return YES;    }]) return NO;
    if (![parser matchDot]) return NO;
    return YES;    }];
    if (![parser matchRule:@"EndOfLine"]) return NO;
    return YES;
};

static PEGParserRule __DOT = ^(PEGParser *parser){
    if (![parser matchString:"."]) return NO;
    if (![parser matchRule:@"Spacing"]) return NO;
    return YES;
};

static PEGParserRule __Declaration = ^(PEGParser *parser){
    if (![parser matchOne:^(PEGParser *parser){
    if ([parser matchOne:^(PEGParser *parser){
    if (![parser matchRule:@"OPTION"]) return NO;
    if (![parser matchString:"case-insensitive"]) return NO;
    [parser matchMany:^(PEGParser *parser){
    if (![parser matchRule:@"HorizSpace"]) return NO;
    return YES;    }];
    if (![parser matchRule:@"EndOfDecl"]) return NO;
    [parser performAction:^(PEGParser *self, NSString *text){ self.compiler.caseInsensitive = YES;     }];    return YES;    }]) return YES;
    if ([parser matchOne:^(PEGParser *parser){
    if (![parser matchRule:@"PROPERTY"]) return NO;
    [parser matchOne:^(PEGParser *parser){
    if (![parser matchRule:@"PropParamaters"]) return NO;
    [parser performAction:^(PEGParser *self, NSString *text){ [self.compiler parsedPropertyParameters:text];     }];    return YES;    }];
    if (![parser matchRule:@"PropIdentifier"]) return NO;
    [parser performAction:^(PEGParser *self, NSString *text){ [self.compiler parsedPropertyType:text];     }];    [parser beginCapture];
    [parser matchMany:^(PEGParser *parser){
    if (![parser matchString:"*"]) return NO;
    return YES;    }];
    [parser endCapture];
    [parser matchMany:^(PEGParser *parser){
    if (![parser matchRule:@"HorizSpace"]) return NO;
    return YES;    }];
    [parser performAction:^(PEGParser *self, NSString *text){ [self.compiler parsedPropertyStars:text];     }];    if (![parser matchRule:@"PropIdentifier"]) return NO;
    if (![parser matchRule:@"EndOfDecl"]) return NO;
    [parser performAction:^(PEGParser *self, NSString *text){ [self.compiler parsedPropertyName:text];     }];    return YES;    }]) return YES;
    return NO;    }]) return NO;
    return YES;
};

static PEGParserRule __Definition = ^(PEGParser *parser){
    if (![parser matchRule:@"Identifier"]) return NO;
    [parser performAction:^(PEGParser *self, NSString *text){ [self.compiler startRule:text];     }];    if (![parser matchRule:@"LEFTARROW"]) return NO;
    if (![parser matchRule:@"Expression"]) return NO;
    [parser performAction:^(PEGParser *self, NSString *text){ [self.compiler parsedRule];     }];    return YES;
};

static PEGParserRule __END = ^(PEGParser *parser){
    if (![parser matchString:">"]) return NO;
    if (![parser matchRule:@"Spacing"]) return NO;
    return YES;
};

static PEGParserRule __Effect = ^(PEGParser *parser){
    if (![parser matchOne:^(PEGParser *parser){
    if ([parser matchOne:^(PEGParser *parser){
    if (![parser matchRule:@"Code"]) return NO;
    [parser performAction:^(PEGParser *self, NSString *text){ [self.compiler parsedCode:text];     }];    return YES;    }]) return YES;
    if ([parser matchOne:^(PEGParser *parser){
    if (![parser matchRule:@"Action"]) return NO;
    [parser performAction:^(PEGParser *self, NSString *text){ [self.compiler parsedAction:text];     }];    return YES;    }]) return YES;
    if ([parser matchOne:^(PEGParser *parser){
    if (![parser matchRule:@"BEGIN"]) return NO;
    [parser performAction:^(PEGParser *self, NSString *text){ [self.compiler beginCapture];     }];    return YES;    }]) return YES;
    if ([parser matchOne:^(PEGParser *parser){
    if (![parser matchRule:@"END"]) return NO;
    [parser performAction:^(PEGParser *self, NSString *text){ [self.compiler endCapture];     }];    return YES;    }]) return YES;
    return NO;    }]) return NO;
    return YES;
};

static PEGParserRule __EndOfDecl = ^(PEGParser *parser){
    if (![parser matchString:";"]) return NO;
    [parser matchMany:^(PEGParser *parser){
    if (![parser matchRule:@"HorizSpace"]) return NO;
    return YES;    }];
    if (![parser matchOne:^(PEGParser *parser){
    if ([parser matchOne:^(PEGParser *parser){
    if (![parser matchRule:@"EndOfLine"]) return NO;
    return YES;    }]) return YES;
    if ([parser matchOne:^(PEGParser *parser){
    if (![parser matchRule:@"Comment"]) return NO;
    return YES;    }]) return YES;
    return NO;    }]) return NO;
    return YES;
};

static PEGParserRule __EndOfFile = ^(PEGParser *parser){
    if (![parser lookAhead:^(PEGParser *parser){
    if ([parser matchDot]) return NO;
    return YES;    }]) return NO;
    return YES;
};

static PEGParserRule __EndOfLine = ^(PEGParser *parser){
    if (![parser matchOne:^(PEGParser *parser){
    if ([parser matchOne:^(PEGParser *parser){
    if (![parser matchString:"\r\n"]) return NO;
    return YES;    }]) return YES;
    if ([parser matchOne:^(PEGParser *parser){
    if (![parser matchString:"\n"]) return NO;
    return YES;    }]) return YES;
    if ([parser matchOne:^(PEGParser *parser){
    if (![parser matchString:"\r"]) return NO;
    return YES;    }]) return YES;
    return NO;    }]) return NO;
    return YES;
};

static PEGParserRule __Expression = ^(PEGParser *parser){
    if (![parser matchRule:@"Sequence"]) return NO;
    [parser matchMany:^(PEGParser *parser){
    if (![parser matchRule:@"SLASH"]) return NO;
    if (![parser matchRule:@"Sequence"]) return NO;
    [parser performAction:^(PEGParser *self, NSString *text){ [self.compiler parsedAlternate];     }];    return YES;    }];
    return YES;
};

static PEGParserRule __Grammar = ^(PEGParser *parser){
    if (![parser matchRule:@"Spacing"]) return NO;
    [parser matchMany:^(PEGParser *parser){
    if (![parser matchRule:@"Declaration"]) return NO;
    return YES;    }];
    if (![parser matchRule:@"Spacing"]) return NO;
    if (![parser matchMany:^(PEGParser *parser){
    if (![parser matchRule:@"Definition"]) return NO;
    return YES;    }]) return NO;
    if (![parser matchRule:@"EndOfFile"]) return NO;
    return YES;
};

static PEGParserRule __HorizSpace = ^(PEGParser *parser){
    if (![parser matchOne:^(PEGParser *parser){
    if ([parser matchOne:^(PEGParser *parser){
    if (![parser matchString:" "]) return NO;
    return YES;    }]) return YES;
    if ([parser matchOne:^(PEGParser *parser){
    if (![parser matchString:"\t"]) return NO;
    return YES;    }]) return YES;
    return NO;    }]) return NO;
    return YES;
};

static PEGParserRule __IdentCont = ^(PEGParser *parser){
    if (![parser matchOne:^(PEGParser *parser){
    if ([parser matchOne:^(PEGParser *parser){
    if (![parser matchRule:@"IdentStart"]) return NO;
    return YES;    }]) return YES;
    if ([parser matchOne:^(PEGParser *parser){
    if (![parser matchClass:(unsigned char *)"\000\000\000\000\000\000\377\003\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"]) return NO;
    return YES;    }]) return YES;
    return NO;    }]) return NO;
    return YES;
};

static PEGParserRule __IdentStart = ^(PEGParser *parser){
    if (![parser matchClass:(unsigned char *)"\000\000\000\000\000\000\000\000\376\377\377\207\376\377\377\007\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"]) return NO;
    return YES;
};

static PEGParserRule __Identifier = ^(PEGParser *parser){
    [parser beginCapture];
    if (![parser matchRule:@"IdentStart"]) return NO;
    [parser matchMany:^(PEGParser *parser){
    if (![parser matchRule:@"IdentCont"]) return NO;
    return YES;    }];
    [parser endCapture];
    if (![parser matchRule:@"Spacing"]) return NO;
    return YES;
};

static PEGParserRule __LEFTARROW = ^(PEGParser *parser){
    if (![parser matchString:"<-"]) return NO;
    if (![parser matchRule:@"Spacing"]) return NO;
    return YES;
};

static PEGParserRule __Literal = ^(PEGParser *parser){
    if (![parser matchOne:^(PEGParser *parser){
    if ([parser matchOne:^(PEGParser *parser){
    if (![parser matchClass:(unsigned char *)"\000\000\000\000\200\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"]) return NO;
    [parser beginCapture];
    [parser matchMany:^(PEGParser *parser){
    if (![parser lookAhead:^(PEGParser *parser){
    if ([parser matchClass:(unsigned char *)"\000\000\000\000\200\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"]) return NO;
    return YES;    }]) return NO;
    if (![parser matchRule:@"Char"]) return NO;
    return YES;    }];
    [parser endCapture];
    if (![parser matchClass:(unsigned char *)"\000\000\000\000\200\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"]) return NO;
    if (![parser matchRule:@"Spacing"]) return NO;
    return YES;    }]) return YES;
    if ([parser matchOne:^(PEGParser *parser){
    if (![parser matchClass:(unsigned char *)"\000\000\000\000\004\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"]) return NO;
    [parser beginCapture];
    [parser matchMany:^(PEGParser *parser){
    if (![parser lookAhead:^(PEGParser *parser){
    if ([parser matchClass:(unsigned char *)"\000\000\000\000\004\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"]) return NO;
    return YES;    }]) return NO;
    if (![parser matchRule:@"Char"]) return NO;
    return YES;    }];
    [parser endCapture];
    if (![parser matchClass:(unsigned char *)"\000\000\000\000\004\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"]) return NO;
    if (![parser matchRule:@"Spacing"]) return NO;
    return YES;    }]) return YES;
    return NO;    }]) return NO;
    return YES;
};

static PEGParserRule __NOT = ^(PEGParser *parser){
    if (![parser matchString:"!"]) return NO;
    if (![parser matchRule:@"Spacing"]) return NO;
    return YES;
};

static PEGParserRule __OPEN = ^(PEGParser *parser){
    if (![parser matchString:"("]) return NO;
    if (![parser matchRule:@"Spacing"]) return NO;
    return YES;
};

static PEGParserRule __OPTION = ^(PEGParser *parser){
    if (![parser matchString:"@option"]) return NO;
    if (![parser matchMany:^(PEGParser *parser){
    if (![parser matchRule:@"HorizSpace"]) return NO;
    return YES;    }]) return NO;
    return YES;
};

static PEGParserRule __PLUS = ^(PEGParser *parser){
    if (![parser matchString:"+"]) return NO;
    if (![parser matchRule:@"Spacing"]) return NO;
    return YES;
};

static PEGParserRule __PROPERTY = ^(PEGParser *parser){
    if (![parser matchString:"@property"]) return NO;
    if (![parser matchMany:^(PEGParser *parser){
    if (![parser matchRule:@"HorizSpace"]) return NO;
    return YES;    }]) return NO;
    return YES;
};

static PEGParserRule __Prefix = ^(PEGParser *parser){
    if (![parser matchOne:^(PEGParser *parser){
    if ([parser matchOne:^(PEGParser *parser){
    if (![parser matchRule:@"AND"]) return NO;
    if (![parser matchRule:@"Suffix"]) return NO;
    [parser performAction:^(PEGParser *self, NSString *text){ [self.compiler parsedLookAhead];     }];    return YES;    }]) return YES;
    if ([parser matchOne:^(PEGParser *parser){
    if (![parser matchRule:@"NOT"]) return NO;
    if (![parser matchRule:@"Suffix"]) return NO;
    [parser performAction:^(PEGParser *self, NSString *text){ [self.compiler parsedNegativeLookAhead];     }];    return YES;    }]) return YES;
    if ([parser matchOne:^(PEGParser *parser){
    if (![parser matchRule:@"AND"]) return NO;
    if (![parser matchRule:@"Action"]) return NO;
    [parser performAction:^(PEGParser *self, NSString *text){ [self.compiler parsedLookAhead:text];     }];    return YES;    }]) return YES;
    if ([parser matchOne:^(PEGParser *parser){
    if (![parser matchRule:@"NOT"]) return NO;
    if (![parser matchRule:@"Action"]) return NO;
    [parser performAction:^(PEGParser *self, NSString *text){ [self.compiler parsedNegativeLookAhead:text];     }];    return YES;    }]) return YES;
    if ([parser matchOne:^(PEGParser *parser){
    if (![parser matchRule:@"Suffix"]) return NO;
    return YES;    }]) return YES;
    if ([parser matchOne:^(PEGParser *parser){
    if (![parser matchRule:@"Effect"]) return NO;
    return YES;    }]) return YES;
    return NO;    }]) return NO;
    return YES;
};

static PEGParserRule __Primary = ^(PEGParser *parser){
    if (![parser matchOne:^(PEGParser *parser){
    if ([parser matchOne:^(PEGParser *parser){
    if (![parser matchRule:@"Identifier"]) return NO;
    if (![parser lookAhead:^(PEGParser *parser){
    if ([parser matchRule:@"LEFTARROW"]) return NO;
    return YES;    }]) return NO;
    [parser performAction:^(PEGParser *self, NSString *text){ [self.compiler parsedIdentifier:text];     }];    return YES;    }]) return YES;
    if ([parser matchOne:^(PEGParser *parser){
    if (![parser matchRule:@"OPEN"]) return NO;
    if (![parser matchRule:@"Expression"]) return NO;
    if (![parser matchRule:@"CLOSE"]) return NO;
    return YES;    }]) return YES;
    if ([parser matchOne:^(PEGParser *parser){
    if (![parser matchRule:@"Literal"]) return NO;
    [parser performAction:^(PEGParser *self, NSString *text){ [self.compiler parsedLiteral:text];     }];    return YES;    }]) return YES;
    if ([parser matchOne:^(PEGParser *parser){
    if (![parser matchRule:@"Class"]) return NO;
    [parser performAction:^(PEGParser *self, NSString *text){ [self.compiler parsedClass:text];     }];    return YES;    }]) return YES;
    if ([parser matchOne:^(PEGParser *parser){
    if (![parser matchRule:@"DOT"]) return NO;
    [parser performAction:^(PEGParser *self, NSString *text){ [self.compiler parsedDot];     }];    return YES;    }]) return YES;
    return NO;    }]) return NO;
    return YES;
};

static PEGParserRule __PropIdentifier = ^(PEGParser *parser){
    [parser beginCapture];
    if (![parser matchRule:@"IdentStart"]) return NO;
    [parser matchMany:^(PEGParser *parser){
    if (![parser matchRule:@"IdentCont"]) return NO;
    return YES;    }];
    [parser endCapture];
    [parser matchMany:^(PEGParser *parser){
    if (![parser matchRule:@"HorizSpace"]) return NO;
    return YES;    }];
    return YES;
};

static PEGParserRule __PropParamaters = ^(PEGParser *parser){
    [parser beginCapture];
    if (![parser matchString:"("]) return NO;
    if (![parser matchMany:^(PEGParser *parser){
    if (![parser matchClass:(unsigned char *)"\377\377\377\377\377\375\377\377\377\377\377\377\377\377\377\377\377\377\377\377\377\377\377\377\377\377\377\377\377\377\377\377"]) return NO;
    return YES;    }]) return NO;
    if (![parser matchString:")"]) return NO;
    [parser endCapture];
    if (![parser matchMany:^(PEGParser *parser){
    if (![parser matchRule:@"HorizSpace"]) return NO;
    return YES;    }]) return NO;
    return YES;
};

static PEGParserRule __QUESTION = ^(PEGParser *parser){
    if (![parser matchString:"?"]) return NO;
    if (![parser matchRule:@"Spacing"]) return NO;
    return YES;
};

static PEGParserRule __Range = ^(PEGParser *parser){
    if (![parser matchOne:^(PEGParser *parser){
    if ([parser matchOne:^(PEGParser *parser){
    if (![parser matchRule:@"Char"]) return NO;
    if (![parser matchString:"-"]) return NO;
    if (![parser matchRule:@"Char"]) return NO;
    return YES;    }]) return YES;
    if ([parser matchOne:^(PEGParser *parser){
    if (![parser matchRule:@"Char"]) return NO;
    return YES;    }]) return YES;
    return NO;    }]) return NO;
    return YES;
};

static PEGParserRule __SLASH = ^(PEGParser *parser){
    if (![parser matchString:"/"]) return NO;
    if (![parser matchRule:@"Spacing"]) return NO;
    return YES;
};

static PEGParserRule __STAR = ^(PEGParser *parser){
    if (![parser matchString:"*"]) return NO;
    if (![parser matchRule:@"Spacing"]) return NO;
    return YES;
};

static PEGParserRule __Sequence = ^(PEGParser *parser){
    [parser matchOne:^(PEGParser *parser){
    if (![parser matchRule:@"Prefix"]) return NO;
    return YES;    }];
    [parser matchMany:^(PEGParser *parser){
    if (![parser matchRule:@"Prefix"]) return NO;
    [parser performAction:^(PEGParser *self, NSString *text){ [self.compiler append];     }];    return YES;    }];
    return YES;
};

static PEGParserRule __Space = ^(PEGParser *parser){
    if (![parser matchOne:^(PEGParser *parser){
    if ([parser matchOne:^(PEGParser *parser){
    if (![parser matchString:" "]) return NO;
    return YES;    }]) return YES;
    if ([parser matchOne:^(PEGParser *parser){
    if (![parser matchString:"\t"]) return NO;
    return YES;    }]) return YES;
    if ([parser matchOne:^(PEGParser *parser){
    if (![parser matchRule:@"EndOfLine"]) return NO;
    return YES;    }]) return YES;
    return NO;    }]) return NO;
    return YES;
};

static PEGParserRule __Spacing = ^(PEGParser *parser){
    [parser matchMany:^(PEGParser *parser){
    if (![parser matchOne:^(PEGParser *parser){
    if ([parser matchOne:^(PEGParser *parser){
    if (![parser matchRule:@"Space"]) return NO;
    return YES;    }]) return YES;
    if ([parser matchOne:^(PEGParser *parser){
    if (![parser matchRule:@"Comment"]) return NO;
    return YES;    }]) return YES;
    return NO;    }]) return NO;
    return YES;    }];
    return YES;
};

static PEGParserRule __Suffix = ^(PEGParser *parser){
    if (![parser matchRule:@"Primary"]) return NO;
    [parser matchOne:^(PEGParser *parser){
    if (![parser matchOne:^(PEGParser *parser){
    if ([parser matchOne:^(PEGParser *parser){
    if (![parser matchRule:@"QUESTION"]) return NO;
    [parser performAction:^(PEGParser *self, NSString *text){ [self.compiler parsedQuestion];     }];    return YES;    }]) return YES;
    if ([parser matchOne:^(PEGParser *parser){
    if (![parser matchRule:@"STAR"]) return NO;
    [parser performAction:^(PEGParser *self, NSString *text){ [self.compiler parsedStar];     }];    return YES;    }]) return YES;
    if ([parser matchOne:^(PEGParser *parser){
    if (![parser matchRule:@"PLUS"]) return NO;
    [parser performAction:^(PEGParser *self, NSString *text){ [self.compiler parsedPlus];     }];    return YES;    }]) return YES;
    return NO;    }]) return NO;
    return YES;    }];
    return YES;
};


- (BOOL) _parse
{
    if (!_string)
    {
        _string = [NSString new];
        _limit = 0;
        _index = 0;
    }
    yybegin= yyend= _index;
    _capturing = YES;
    
    BOOL matched = [self matchRule:@"Grammar"];
    
    if (matched)
        [self yyDone];
    [self yyCommit];
    
    [_string release];
    _string = nil;
    
    return matched;
}


//==================================================================================================
#pragma mark -
#pragma mark NSObject Methods
//==================================================================================================

- (id) init
{
    self = [super init];
    
    if (self)
    {
        _rules = [NSMutableDictionary new];
        _captures = [NSMutableArray new];
        [self addRule:__AND withName:@"AND"];
        [self addRule:__Action withName:@"Action"];
        [self addRule:__BEGIN withName:@"BEGIN"];
        [self addRule:__CLOSE withName:@"CLOSE"];
        [self addRule:__Char withName:@"Char"];
        [self addRule:__Class withName:@"Class"];
        [self addRule:__Code withName:@"Code"];
        [self addRule:__Comment withName:@"Comment"];
        [self addRule:__DOT withName:@"DOT"];
        [self addRule:__Declaration withName:@"Declaration"];
        [self addRule:__Definition withName:@"Definition"];
        [self addRule:__END withName:@"END"];
        [self addRule:__Effect withName:@"Effect"];
        [self addRule:__EndOfDecl withName:@"EndOfDecl"];
        [self addRule:__EndOfFile withName:@"EndOfFile"];
        [self addRule:__EndOfLine withName:@"EndOfLine"];
        [self addRule:__Expression withName:@"Expression"];
        [self addRule:__Grammar withName:@"Grammar"];
        [self addRule:__HorizSpace withName:@"HorizSpace"];
        [self addRule:__IdentCont withName:@"IdentCont"];
        [self addRule:__IdentStart withName:@"IdentStart"];
        [self addRule:__Identifier withName:@"Identifier"];
        [self addRule:__LEFTARROW withName:@"LEFTARROW"];
        [self addRule:__Literal withName:@"Literal"];
        [self addRule:__NOT withName:@"NOT"];
        [self addRule:__OPEN withName:@"OPEN"];
        [self addRule:__OPTION withName:@"OPTION"];
        [self addRule:__PLUS withName:@"PLUS"];
        [self addRule:__PROPERTY withName:@"PROPERTY"];
        [self addRule:__Prefix withName:@"Prefix"];
        [self addRule:__Primary withName:@"Primary"];
        [self addRule:__PropIdentifier withName:@"PropIdentifier"];
        [self addRule:__PropParamaters withName:@"PropParamaters"];
        [self addRule:__QUESTION withName:@"QUESTION"];
        [self addRule:__Range withName:@"Range"];
        [self addRule:__SLASH withName:@"SLASH"];
        [self addRule:__STAR withName:@"STAR"];
        [self addRule:__Sequence withName:@"Sequence"];
        [self addRule:__Space withName:@"Space"];
        [self addRule:__Spacing withName:@"Spacing"];
        [self addRule:__Suffix withName:@"Suffix"];
    }
    
    return self;
}


- (void) dealloc
{
    [_string release];
    [_rules release];
    [_captures release];

    [super dealloc];
}


//==================================================================================================
#pragma mark -
#pragma mark Public Methods
//==================================================================================================

- (void) addRule:(PEGParserRule)rule withName:(NSString *)name
{
    NSMutableArray *rules = [_rules objectForKey:name];
    if (!rules)
    {
        rules = [NSMutableArray new];
        [_rules setObject:rules forKey:name];
        [rules release];
    }
    
    [rules addObject:rule];
}


- (BOOL) parse
{
    NSAssert(_dataSource != nil, @"can't call -parse without specifying a data source");
    return [self _parse];
}


- (BOOL) parseString:(NSString *)string
{
    _string = [string copy];
    _limit  = [_string lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    _index  = 0;
    BOOL retval = [self _parse];
    [_string release];
    _string = nil;
    return retval;
}


@end

