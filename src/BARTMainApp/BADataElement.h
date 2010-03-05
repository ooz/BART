//
//  BADataElement.h
//  BARTCommandLine
//
//  Created by First Last on 10/29/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BAElement.h"


@interface BADataElement : BAElement {
    
   // fuer Datenelemente ist Vorgabe der Typen okay - Vimage, isis::image - 


    int numberRows;
    int numberCols;
    int numberSlices;
    int numberTimesteps;
    //enum ImageType imageType;
    enum ImageDataType imageDataType;
    
    int repetitionTimeInMs;
   // NSArray *allDatasetProperties;
    NSDictionary *imagePropertiesMap;
    
    
    
}

@property (readonly, assign) int numberRows; 
@property (readonly, assign) int numberCols; 
@property (readonly, assign) int numberSlices; 
@property (readonly, assign) int numberTimesteps;
@property (readonly, assign) enum ImageDataType imageDataType;



-(id)initWith:(NSArray*) aType;

-(id)initWithDatasetFile:(NSString*)path ofImageDataType:(enum ImageDataType)type;

-(id)initWithDataType:(enum ImageDataType)type andRows:(int) rows andCols:(int)cols andSlices:(int)slices andTimesteps:(int) tsteps;


-(void)dealloc;



@end


#pragma mark -

@interface BADataElement (AbstractMethods)

-(short)getShortVoxelValueAtRow: (int)r col:(int)c slice:(int)s timestep:(int)t;

-(float)getFloatVoxelValueAtRow: (int)r col:(int)c slice:(int)s timestep:(int)t;

-(void)setVoxelValue:(NSNumber*)val atRow: (int)r col:(int)c slice:(int)s timestep:(int)t;

//-(BADataElement*)CreateNewDataElement: withSize:(NSSize*)size andType:(NSString*)type; 

-(void)WriteDataElementToFile:(NSString*)path;

-(BOOL)sliceIsZero:(int)slice;

-(void)setImageProperty:(enum ImagePropertyID)key withValue:(id) value;

-(id)getImageProperty:(enum ImagePropertyID)key;

-(short*)getShortDataFromSlice:(int)sliceNr;

-(float*)getFloatDataFromSlice:(int)sliceNr;





@end