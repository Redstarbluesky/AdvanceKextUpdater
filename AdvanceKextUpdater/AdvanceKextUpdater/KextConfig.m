//
//  KextConfig.m
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 8/24/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KextConfig.h"
#import "JSONParser.h"
#import "KextHandler.h"
#import "Task.h"

@implementation KextConfig
- (instancetype) initWithConfig: (NSString *) configFile {
    configPath = configFile;
    if([[NSFileManager defaultManager] fileExistsAtPath:configPath])
        [self parseConfig];
    else return nil;
    return self;
}

- (instancetype) initWithKextName: (NSString *) kextName {
    kextName = [kextName stringByDeletingPathExtension];
    configPath = [self searchConfigPath:kextName];
    if([[NSFileManager defaultManager] fileExistsAtPath:configPath])
        [self parseConfig];
    else return nil;
    return self;
}

- (instancetype) initWithKextName: (NSString *) kextName URL: (NSString *) configURL {
    kextName = [kextName stringByDeletingPathExtension];
    configPath = [self appendConfigJSON:[[KextHandler kextCachePath] stringByAppendingPathComponent:kextName]];
    // Save config.json from URL to cache
    [URLTask conditionalGet:[NSURL URLWithString:configURL] toFile:configPath];
    if([[NSFileManager defaultManager] fileExistsAtPath:configPath])
        [self parseConfig];
    else return nil;
    return self;
}

- (void) parseConfig {
    configParsed = [JSONParser parseFromFile:configPath];
    // Associate parsed info with the public methods
    self.authors     = [ConfigAuthor createFromArrayOfDictionary:[configParsed objectForKey:@"authors"]];
    self.binaries    = [configParsed objectForKey:@"bin"];       // Needs own class
    self.changes     = [configParsed objectForKey:@"changes"];   // Markdown
    self.conflict    = [ConfigConflictKexts initWithDictionaryOrNull:[configParsed objectForKey:@"conflict"]];
    self.guide       = [configParsed objectForKey:@"guide"];     // Markdown or URL
    self.homepage    = [configParsed objectForKey:@"homepage"];
    self.hwRequirments     = [configParsed objectForKey:@"hw"];  // Needs own class
    self.kextName    = [configParsed objectForKey:@"kext"];
    self.lastMacOSVersion  = [configParsed objectForKey:@"last"];// part of macOS version checker class
    self.license     = [self licenseToArrayOfLicense:[configParsed objectForKey:@"license"]];
    self.name        = [configParsed objectForKey:@"name"];
    self.replacedBy  = [ConfigReplacedByKexts initWithDictionaryOrNull:[configParsed objectForKey:@"replaced_by"]];
    self.requirments = [ConfigRequiredKexts initWithDictionaryOrNull:[configParsed objectForKey:@"require"]];// Needs own class
    self.shortDescription  = [configParsed objectForKey:@"description"];
    self.sinceMacOSVersion = [configParsed objectForKey:@"since"];// part of macOS version checker class
    self.suggestions = [configParsed objectForKey:@"suggest"];   // Needs own class
    self.swRequirments = [configParsed objectForKey:@"sw"];      // Needs own class
    self.tags        = [[configParsed objectForKey:@"tags"] componentsSeparatedByString:@","]; // Trim too???
    self.target      = [configParsed objectForKey:@"target"];    // Set based on macOS version
    self.time        = [NSDate dateWithNaturalLanguageString:[configParsed objectForKey:@"time"]];
    self.version     = [configParsed objectForKey:@"version"]; // Needs own class (in relation with versions)
    self.versions    = [configParsed objectForKey:@"versions"];  // Needs own class
}

- (NSArray *) licenseToArrayOfLicense: (id) license {
    NSMutableArray *licenses = [NSMutableArray array];
    if([license isKindOfClass:[NSString class]]) {
        [licenses addObject:license];
    } else if ([license isKindOfClass:[NSArray class]]) {
        licenses = license;
    }
    return [licenses copy];
}

/**
 * This method will search for config files in the following folders (${kextName} as subfolder and ~/Library/Application Support/AdvanceKextUpdater as ${ROOT}):
 * - ${ROOT}/kext_db
 * - ${ROOT}/Cache/kexts
 * - tmp/AdvanceKextUpdater/kexts
 *
 * @return config.json file
 */
- (NSString *) searchConfigPath: (NSString *) kextName {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *kextPath = [[KextHandler kextDBPath] stringByAppendingPathComponent:kextName];
    if([fm fileExistsAtPath:kextPath]) {
        return [self appendConfigJSON:kextPath];
    }
    kextPath = [[KextHandler kextCachePath] stringByAppendingPathComponent:kextName];
    if([fm fileExistsAtPath:kextPath]) {
        return [self appendConfigJSON:kextPath];
    }
    kextPath = [[KextHandler kextTmpPath] stringByAppendingPathComponent:kextName];
    if([fm fileExistsAtPath:kextPath]) {
        return [self appendConfigJSON:kextPath];
    }
    return nil;
}

- (NSString *) appendConfigJSON: (NSString *) kextPath {
    return [[kextPath stringByAppendingPathComponent:@"config"] stringByAppendingPathExtension:@"json"];
}

@end
