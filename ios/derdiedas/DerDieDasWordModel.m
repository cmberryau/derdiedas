//
//  DerDieDasWordModel.m
//  derdiedas
//
//  Created by Christopher Berry on 18/03/2014.
//  Copyright (c) 2014 Christopher Berry. All rights reserved.
//
//  DerDieDas is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 2 of the License, or
//  (at your option) any later version.
//
//  DerDieDas is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with DerDieDas. If not, see <http://www.gnu.org/licenses/>.

#import "DerDieDasWordModel.h"

@implementation DerDieDasWordModel

-(DerDieDasWordModel *) initWithManagedObjectContext:(NSManagedObjectContext *) context
{
    if(context == nil)
    {
        [NSException raise:@"Passed NSMangedObjectContext cannot be null" format:@""];
    }
    
    _managedObjectContext = context;
    
    NSFetchRequest * fetch_request = [[NSFetchRequest alloc] init];
    NSEntityDescription * entity_description = [NSEntityDescription entityForName:@"Word" inManagedObjectContext:_managedObjectContext];
    
    [fetch_request setEntity:entity_description];
    
    NSError * error;
    NSUInteger count = [_managedObjectContext countForFetchRequest:fetch_request error:&error];
    
    if(count <= 0)
    {
        [self addDefaultWords];
    }
    
    return self;
}

// Returns a pointer to the NSFetchedResultsController object
-(NSFetchedResultsController *) fetchedResultsController
{
    if(_fetchedResultsController == nil)
    {
        NSFetchRequest * fetch_request = [[NSFetchRequest alloc] init];
        NSEntityDescription * entity_description = [NSEntityDescription entityForName:@"Word" inManagedObjectContext:_managedObjectContext];
        
        [fetch_request setEntity:entity_description];
        
        NSSortDescriptor * sort_descriptor = [[NSSortDescriptor alloc] initWithKey:@"fail_rate" ascending:NO];
        NSArray * sort_descriptors_array = @[sort_descriptor];
        
        [fetch_request setSortDescriptors:sort_descriptors_array];
        
        _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetch_request managedObjectContext:_managedObjectContext sectionNameKeyPath:nil cacheName:nil];
        
        NSError * error;
        BOOL success = [_fetchedResultsController performFetch:&error];
        
        if(!success)
        {
            [NSException raise:@"fetchedResultsController performFetch resulted in failure" format:@""];
        }
    }
    
    return _fetchedResultsController;
}

// Adds the default words to the model
-(void) addDefaultWords
{
    [self addWord:@"die Katze"];
    [self addWord:@"die Gesundheit"];
    [self addWord:@"das Auto"];
    [self addWord:@"der Entsafter"];
    [self addWord:@"das Bein"];
    [self addWord:@"der Kater"];
    [self addWord:@"die Tür"];
}

// Returns true if the word already exists in the model
-(BOOL) contains:(NSString *) whole_word
{
    if(whole_word == nil)
        return false;
    
    NSString * trimmed_word = [whole_word stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSArray * strings = [trimmed_word componentsSeparatedByString:@" "];
    
    if([strings count] != 2)
        return false;
    
    NSString * article = [strings[0] lowercaseString];
    NSString * characters = [strings[1] capitalizedString];
    
    NSFetchRequest * fetch_request = [[NSFetchRequest alloc] init];
    NSEntityDescription * entity_description = [NSEntityDescription entityForName:@"Word" inManagedObjectContext:_managedObjectContext];
    
    [fetch_request setEntity:entity_description];
    
    NSPredicate * search_predicate = [NSPredicate predicateWithFormat:@"article == %@ AND characters == %@", article, characters];
    
    [fetch_request setPredicate:search_predicate];
    
    NSError * error;
    NSUInteger count = [_managedObjectContext countForFetchRequest:fetch_request error:&error];
    
    if(count > 0)
    {
        return true;
    }
    
    return false;
}

// Returns true if the word already exists in the model
-(BOOL) contains:(NSString *) article characters:(NSString *)characters
{
    NSFetchRequest * fetch_request = [[NSFetchRequest alloc] init];
    NSEntityDescription * entity_description = [NSEntityDescription entityForName:@"Word" inManagedObjectContext:_managedObjectContext];
    
    [fetch_request setEntity:entity_description];
    
    NSPredicate * search_predicate = [NSPredicate predicateWithFormat:@"article == %@ AND characters == %@", article, characters];
    
    [fetch_request setPredicate:search_predicate];
    
    NSError * error;
    NSUInteger count = [_managedObjectContext countForFetchRequest:fetch_request error:&error];
    
    if(count > 0)
    {
        return true;
    }
    
    return false;
}

// Adds a word to the model and returns the newly created object
-(DerDieDasWord *) addWord:(NSString *) whole_word
{
    DerDieDasWord * word = [DerDieDasWord wordWithString:whole_word context:_managedObjectContext];

    return word;
}

// Adds a word to the model and returns the newly created object
-(DerDieDasWord *) addWord:(NSString *) article characters:(NSString *)characters
{
    DerDieDasWord * word = [DerDieDasWord wordWithArticleAndCharacters:article characters:characters context:_managedObjectContext];
    
    return word;
}

// Deletes the word from the model
-(void) remove:(DerDieDasWord *)word
{
    if(word == nil)
    {
        [NSException raise:@"Passed word cannot be null" format:@""];
    }
    
    NSFetchRequest * fetch_request = [[NSFetchRequest alloc] init];
    NSEntityDescription * entity_description = [NSEntityDescription entityForName:@"Word" inManagedObjectContext:_managedObjectContext];
    
    [fetch_request setEntity:entity_description];
    
    NSPredicate * search_predicate = [NSPredicate predicateWithFormat:@"article == %@ AND characters == %@", word.article, word.characters];
    
    [fetch_request setPredicate:search_predicate];
    
    NSError * error;
    NSArray * objects = [_managedObjectContext executeFetchRequest:fetch_request error:&error];
    DerDieDasWord * match = nil;
    
    // only one object returned, this is how it should be
    if([objects count] == 1)
    {
        match = objects[0];
        [_managedObjectContext deleteObject:match];
    }
    // more than one object returned, remove all the objects matching
    else if([objects count] > 1)
    {
        [NSException raise:@"More than one object returned in model search for deleting item" format:@""];
    }
    // no objects returned, a serious error
    else if([objects count] < 1)
    {
        [NSException raise:@"No objects returned in model search for deleting item" format:@""];
    }
    
    [_managedObjectContext save:&error];
}

// Returns the next word, based on it's priority
-(DerDieDasWord *) next
{
    DerDieDasWord * match = [self fetcNextWordNoisy];
    
    if(match == nil)
    {
        [NSException raise:@"Fetched word null" format:@""];
    }
    
    _currentWord = match;
    
    return match;
}

// fetches a word with some random elements added
-(DerDieDasWord *) fetcNextWordNoisy
{
    int random_number = arc4random_uniform(11);
    
    DerDieDasWord * match;
    
    if(random_number < 4)
    {
        match = [self fetchRecentlyAddedWord];
        
        if(match != nil)
        {
            return match;
        }
        
        match = [self fetchRarelyAttemptedWord];
    }
    else
    {
        match = [self fetchDifficultWord];
    }
    
    return match;
}

// fetches a recently added word from the store
-(DerDieDasWord *) fetchRecentlyAddedWord
{
    NSFetchRequest * fetch_request = [[NSFetchRequest alloc] init];
    NSEntityDescription * entity_description = [NSEntityDescription entityForName:@"Word" inManagedObjectContext:_managedObjectContext];
    [fetch_request setEntity:entity_description];
    
    // words that have not been attempted yet, or have no last attempted date
    NSPredicate * search_predicate = [NSPredicate predicateWithFormat:@"(times_attempted = 0) OR (last_attempt = NULL)", [NSDate dateWithTimeIntervalSinceNow:-10]];
    [fetch_request setPredicate:search_predicate];
    
    NSError * error;
    NSArray * objects = [_managedObjectContext executeFetchRequest:fetch_request error:&error];
    
    if([objects count] > 0)
    {
        DerDieDasWord * match = objects[0];
        return match;
    }
    
    return nil;
}

// fetches a word with a high fail rate
-(DerDieDasWord *) fetchDifficultWord
{
    NSFetchRequest * fetch_request = [[NSFetchRequest alloc] init];
    NSEntityDescription * entity_description = [NSEntityDescription entityForName:@"Word" inManagedObjectContext:_managedObjectContext];
    [fetch_request setEntity:entity_description];

    // 5 minute gaps between attempts (includes app downtime)
    NSPredicate * search_predicate = [NSPredicate predicateWithFormat:@"(last_attempt < %@)", [NSDate dateWithTimeIntervalSinceNow:-60 * 5]];
    [fetch_request setPredicate:search_predicate];
    
    // Sort based on their failure rate in a descending order
    NSSortDescriptor * sort_descriptor = [[NSSortDescriptor alloc] initWithKey:@"fail_rate" ascending:NO];
    NSArray * sort_descriptors_array = @[sort_descriptor];
    [fetch_request setSortDescriptors:sort_descriptors_array];
    
    NSError * error;
    NSArray * objects = [_managedObjectContext executeFetchRequest:fetch_request error:&error];
    
    DerDieDasWord * match;
    
    if([objects count] > 0)
    {
        match = objects[0];
        return match;
    }
    
    [fetch_request setPredicate:NULL];
    objects = [_managedObjectContext executeFetchRequest:fetch_request error:&error];
    
    if([objects count] > 0)
    {
        match = objects[0];
        return match;
    }
    
    return nil;
}

// fetches a word that the user has not attempted often
-(DerDieDasWord *) fetchRarelyAttemptedWord
{
    NSFetchRequest * fetch_request = [[NSFetchRequest alloc] init];
    NSEntityDescription * entity_description = [NSEntityDescription entityForName:@"Word" inManagedObjectContext:_managedObjectContext];
    [fetch_request setEntity:entity_description];
    
    // 5 minute gaps between attempts (includes app downtime)
    NSPredicate * search_predicate = [NSPredicate predicateWithFormat:@"(last_attempt < %@)", [NSDate dateWithTimeIntervalSinceNow:-60 * 5]];
    [fetch_request setPredicate:search_predicate];
    
    // Sort words based on how many attempts in a ascending order
    NSSortDescriptor * sort_descriptor = [[NSSortDescriptor alloc] initWithKey:@"times_attempted" ascending:YES];
    NSArray * sort_descriptors_array = @[sort_descriptor];
    [fetch_request setSortDescriptors:sort_descriptors_array];
    
    NSError * error;
    NSArray * objects = [_managedObjectContext executeFetchRequest:fetch_request error:&error];
    
    DerDieDasWord * match;
    
    if([objects count] > 0)
    {
        match = objects[0];
        return match;
    }
    
    [fetch_request setPredicate:NULL];
    objects = [_managedObjectContext executeFetchRequest:fetch_request error:&error];
    
    if([objects count] > 0)
    {
        match = objects[0];
        return match;
    }
    
    return nil;
}

// Returns the current word
-(DerDieDasWord *) current
{
    if(_currentWord == nil)
    {
        _currentWord = [self next];
    }
    
    return _currentWord;
}

// Returns the word at the index
-(DerDieDasWord *)atIndex:(NSInteger)index
{
    NSFetchRequest * fetch_request = [[NSFetchRequest alloc] init];
    NSEntityDescription * entity_description = [NSEntityDescription entityForName:@"Word" inManagedObjectContext:_managedObjectContext];
    
    [fetch_request setEntity:entity_description];
    
    NSError * error;
    NSArray * objects = [_managedObjectContext executeFetchRequest:fetch_request error:&error];
    DerDieDasWord * match = nil;
    
    match = objects[index];
    
    return match;
}

// Returns the number of words
-(NSUInteger) count
{
    NSFetchRequest * fetch_request = [[NSFetchRequest alloc] init];
    NSEntityDescription * entity_description = [NSEntityDescription entityForName:@"Word" inManagedObjectContext:_managedObjectContext];
    
    [fetch_request setEntity:entity_description];
    
    NSError * error;
    
    NSUInteger count = [_managedObjectContext countForFetchRequest:fetch_request error:&error];
    
    if(count == NSNotFound)
    {
        [NSException raise:@"Error attempting to resolve the number of objects in the model" format:@""];
    }
    
    return count;
}

@end
