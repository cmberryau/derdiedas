//
//  EnterWordViewController.m
//  Artikel
//
//  Created by Christopher Berry on 18/03/2014.
//  Copyright (c) 2014 Christopher Berry. All rights reserved.
//
//  Artikel is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 2 of the License, or
//  (at your option) any later version.
//
//  Artikel is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Artikel. If not, see <http://www.gnu.org/licenses/>.

#import "ArtikelEnterWordViewController.h"
#import "ArtikelWordModel.h"
#import "ArtikelAnimationController.h"
#import "ArtikelTableViewController.h"

@interface ArtikelEnterWordViewController ()

@end

@implementation ArtikelEnterWordViewController

ArtikelTableViewController * wordTableController = nil;

#pragma mark - Inherited & Protocol methods

- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if(wordTableController == nil)
    {
        wordTableController = [[ArtikelTableViewController alloc] init];
    }

    // set the field's delegate for UITextFieldDelegate protocol
    self.wordField.delegate = self;
    [self.wordField setPlaceholder:@"e.g die Katze"];
    
    [wordTableController setModel:self.model];
    [[self.model fetchedResultsController] setDelegate:wordTableController];
    wordTableController.tableView = self.wordTable;
    [self.wordTable setDelegate:wordTableController];
    [self.wordTable setDataSource:wordTableController];
    
    self.navigationItem.rightBarButtonItem = wordTableController.editButtonItem;
    
    [wordTableController realignTableView];
}

- (void)viewDidAppear:(BOOL)animated
{
    // subscribe to notifications for keyboard being shown or hidden
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    // unsubscribe from notifications for keyboard being shown or hidden
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillChangeFrameNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self addWordFromTextField];
    
    return YES;
}

#pragma mark - Responding to keyboard events

- (void)adjustConstraintByKeyboardState:(BOOL)showKeyboard
                           keyboardInfo:(NSDictionary *)info
{
    // transform the UIViewAnimationCurve to a UIViewAnimationOptions mask
    UIViewAnimationCurve animationCurve = [info[UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue];
    UIViewAnimationOptions animationOptions = UIViewAnimationOptionBeginFromCurrentState;
    
    // not sure what this does
    animationOptions |= animationCurve << 16;
    
    if (showKeyboard)
    {
        NSValue *keyboardFrameVal = [info objectForKey:UIKeyboardFrameEndUserInfoKey];
        CGRect keyboardFrame = [keyboardFrameVal CGRectValue];
        CGFloat height = keyboardFrame.size.height;
        
        // adjust the constraint constant to include the keyboard's height
        self.constraintToAdjust.constant += height;
    }
    else
    {
        self.constraintToAdjust.constant = 0;
    }
    
    NSTimeInterval animationDuration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    [UIView animateWithDuration:animationDuration delay:0
                        options:animationOptions
                     animations:^{[self.view layoutIfNeeded];}
                     completion:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    [self adjustConstraintByKeyboardState:YES
                             keyboardInfo:userInfo];
    
    [wordTableController realignTableView];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    [self adjustConstraintByKeyboardState:NO
                             keyboardInfo:userInfo];
}

#pragma mark - Artikel related

// adds a word from the current content in the text field
-(void)addWordFromTextField
{
    if([self.model contains:self.wordField.text])
    {
        NSLog(@"Model already contains word, should alert user!");
    }
    else
    {
        ArtikelWord * word = [self.model addWord:self.wordField.text];
        
        if(!word)
        {
            // do not clear the text field, and show that the word is invalid
            [ArtikelAnimationController DoShake:self.wordField.layer
                                         offset:5.0
                                       duration:0.35
                                       delegate:self];
        }
        else
        {
            // clear the text field and show that the word has been added
            self.wordField.text = @"";
            [self.wordTable reloadData];
            [wordTableController realignTableView];
        }
    }
}

@end
