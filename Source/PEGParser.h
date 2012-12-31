//
//  Generated by pegged 0.4.0.
//

#import <Foundation/Foundation.h>


@class Compiler;
@class PEGParser;


@protocol PEGParserDataSource;
typedef NSObject<PEGParserDataSource> PEGParserDataSource;
typedef BOOL (^PEGParserRule)(PEGParser *parser);
typedef void (^PEGParserAction)(PEGParser *self, NSString *text);

@interface PEGParser : NSObject
{
    PEGParserDataSource *_dataSource;
    NSString *_string;
    const char *cstring;
    NSUInteger _index;
    NSUInteger _limit;
    NSMutableDictionary *_rules;

    BOOL _capturing;
    NSUInteger yybegin;
    NSUInteger yyend;
    NSMutableArray *_captures;

    Compiler *_compiler;
}

@property (retain) PEGParserDataSource *dataSource;

@property (readonly) NSUInteger captureStart;
@property (readonly) NSUInteger captureEnd;
@property (readonly) NSString* string;
@property (retain) Compiler *compiler;

- (void) addRule:(PEGParserRule)rule withName:(NSString *)name;

- (void) beginCapture;
- (void) endCapture;
- (void) performAction:(PEGParserAction)action;

- (BOOL) lookAhead:(PEGParserRule)rule;
- (BOOL) invert:(PEGParserRule)rule;
- (BOOL) matchRule:(NSString *)ruleName;
- (BOOL) matchOne:(PEGParserRule)rule;
- (BOOL) matchMany:(PEGParserRule)rule;
- (BOOL) matchDot;
- (BOOL) matchString:(char *)s;
- (BOOL) matchClass:(unsigned char *)bits;

- (BOOL) parse;
- (BOOL) parseString:(NSString *)string;

@end


@protocol PEGParserDataSource

- (NSString *) nextString;

@end

