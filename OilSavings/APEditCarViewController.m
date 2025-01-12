// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

//
//  APEditCarViewController.m
//  OilSavings
//
//  Created by Andi Palo on 5/26/14.
//  Copyright (c) 2014 Andi Palo. All rights reserved.
//

#import "APEditCarViewController.h"
#import <sqlite3.h>

@interface APEditCarViewController ()

@property (nonatomic, weak) IBOutlet UITextField *textField;
@property (nonatomic, weak) IBOutlet UIPickerView *pickerView;

@property (strong, nonatomic) NSMutableArray *pickerData;

@property (strong, nonatomic) NSString *databasePath;
@property (nonatomic) sqlite3 *carDB;
@property (nonatomic, strong) NSArray *energyTypesStrings;
@end

@implementation APEditCarViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    self.energyTypesStrings = [[NSArray alloc]initWithObjects:
                  @"gasoline",
                  @"diesel",
                  nil];
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = self.editedFieldName;
    
    //Root filepath
    NSString *appDir = [[NSBundle mainBundle] resourcePath];
    
    _databasePath = [[NSString alloc] initWithString: [appDir stringByAppendingPathComponent:@"car.sqlite"]];
    
    NSFileManager *filemgr = [NSFileManager defaultManager];
    
    if ([filemgr fileExistsAtPath: _databasePath ] == NO){
        ALog("Error here buddy , could not find car db file");
    }else{
        const char *dbpath = [_databasePath UTF8String];
        
        if (sqlite3_open(dbpath, &_carDB) != SQLITE_OK){
            ALog("Failed to open/create database");
        }
        //Load data
        
        
        NSString *querySQL;
        sqlite3_stmt    *statement;

        if (self.type == kBrandEdit || self.type == kFriendlyNameEdit) {
            querySQL = @"SELECT brand FROM brands ORDER BY brand";
        }else{
            querySQL = [NSString stringWithFormat:
                      @"SELECT model,energy FROM models WHERE brandID = (SELECT id from brands WHERE brand = '%@')",
                      [self.editedObject valueForKeyPath:@"brand"]];
        }
        
        
        const char *query_stmt = [querySQL UTF8String];
        
        if (sqlite3_prepare_v2(_carDB, query_stmt, -1, &statement, NULL) == SQLITE_OK)
        {
            self.pickerData = [[NSMutableArray alloc]init];
            
            while (sqlite3_step(statement) == SQLITE_ROW) {
                NSString *info = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 0)];
                [self.pickerData addObject:info];
            }
            sqlite3_finalize(statement);
        }
        sqlite3_close(_carDB);
        
        //set field equal to the first of the list.
        self.textField.text = self.pickerData[0];
        
    }
}

- (void) saveCarParamsOfModel:(NSString*)model{
    NSString *appDir = [[NSBundle mainBundle] resourcePath];
    
    _databasePath = [[NSString alloc] initWithString: [appDir stringByAppendingPathComponent:@"car.sqlite"]];
    
    NSFileManager *filemgr = [NSFileManager defaultManager];
    
    if ([filemgr fileExistsAtPath: _databasePath ] == NO){
        ALog("Error here buddy , could not find car db file");
    }else{
        const char *dbpath = [_databasePath UTF8String];
        
        if (sqlite3_open(dbpath, &_carDB) != SQLITE_OK){
            ALog("Failed to open/create database");
        }
        //Load data
        
        
        NSString *querySQL;
        querySQL = [NSString stringWithFormat:
                    @"SELECT * FROM parameters WHERE modelID = (SELECT id from models WHERE model = '%@')",
                    [self.editedObject valueForKeyPath:@"model"]];
        sqlite3_stmt    *statement;

        
        const char *query_stmt = [querySQL UTF8String];
        
        if (sqlite3_prepare_v2(_carDB, query_stmt, -1, &statement, NULL) == SQLITE_OK)
        {
            self.pickerData = [[NSMutableArray alloc]init];
            
            while (sqlite3_step(statement) == SQLITE_ROW) {
                [self.editedObject setValue:[NSNumber numberWithInt:sqlite3_column_int(statement, 0)] forKeyPath:@"modelID"];
                [self.editedObject setValue:[NSNumber numberWithDouble:sqlite3_column_double(statement, 1)] forKeyPath:@"pA"];
                [self.editedObject setValue:[NSNumber numberWithDouble:sqlite3_column_double(statement, 2)] forKeyPath:@"pB"];
                [self.editedObject setValue:[NSNumber numberWithDouble:sqlite3_column_double(statement, 3)] forKeyPath:@"pB"];
                [self.editedObject setValue:[NSNumber numberWithDouble:sqlite3_column_double(statement, 4)] forKeyPath:@"pD"];
            }
            sqlite3_finalize(statement);
        }
        //get also type of energy supply
        querySQL = [NSString stringWithFormat:
                    @"SELECT energy FROM models WHERE modelID = '%d')",
                    [[self.editedObject valueForKeyPath:@"modelID"] intValue]];
        
        if (sqlite3_prepare_v2(_carDB, query_stmt, -1, &statement, NULL) == SQLITE_OK)
        {
            self.pickerData = [[NSMutableArray alloc]init];
            
            while (sqlite3_step(statement) == SQLITE_ROW) {
                
                NSString* energy = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 0)];
                
                if ([energy isEqualToString:[self.energyTypesStrings objectAtIndex:kEnergyGasoline]]) {
                    [self.editedObject setValue:[NSNumber numberWithInt:kEnergyGasoline] forKeyPath:@"energy"];
                }else if ([energy isEqualToString:[self.energyTypesStrings objectAtIndex:kEnergyDiesel]]){
                    [self.editedObject setValue:[NSNumber numberWithInt:kEnergyDiesel] forKeyPath:@"energy"];
                }
            }
            sqlite3_finalize(statement);
        }
        
        sqlite3_close(_carDB);
        
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Configure the user interface according to state.
    if (self.type == kFriendlyNameEdit) {
        self.textField.hidden = NO;
        self.pickerView.hidden = YES;

        self.textField.text = [self.editedObject valueForKey:self.editedFieldKey];
        self.textField.placeholder = self.title;
        [self.textField becomeFirstResponder];
    }
    else {
        self.textField.hidden = YES;
        self.pickerView.hidden = NO;
        
        self.pickerData = self.pickerData;
    }
    self.pickerView.delegate = self;
    self.pickerView.showsSelectionIndicator = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - Save and cancel operations

- (IBAction)save:(id)sender
{
    // Set the action name for the undo operation.
    NSUndoManager * undoManager = [[self.editedObject managedObjectContext] undoManager];
    [undoManager setActionName:[NSString stringWithFormat:@"%@", self.editedFieldName]];
    
    [self.editedObject setValue:self.textField.text forKey:self.editedFieldKey];
    
    //if we chose model then save all car parameters
    if (self.type == kModelEdit) {
        [self saveCarParamsOfModel:self.textField.text];
//        ALog("After set %@", [self.editedObject valueForKeyPath:@"modelID"]);
    }
    [self.navigationController popViewControllerAnimated:YES];
}


- (IBAction)cancel:(id)sender
{
    // Don't pass current value to the edited object, just pop.
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - Manage whether editing a date

- (void)setEditedFieldKey:(NSString *)editedFieldKey
{
    if (![_editedFieldKey isEqualToString:editedFieldKey]) {
        _editedFieldKey = editedFieldKey;
    }
}

#pragma mark -
#pragma mark PickerView DataSource

- (NSInteger)numberOfComponentsInPickerView:
(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView
numberOfRowsInComponent:(NSInteger)component
{
    return _pickerData.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView
             titleForRow:(NSInteger)row
            forComponent:(NSInteger)component
{
    return _pickerData[row];
}

#pragma mark -
#pragma mark PickerView Delegate
-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row
      inComponent:(NSInteger)component
{
    self.textField.text = _pickerData[row];
}

- (void)dealloc{
    sqlite3_close(_carDB);
}

@end
