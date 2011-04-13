//
//  BAProcedureController.m
//  BARTCommandLine
//
//  Created by Lydia Hellrung on 10/29/09.
//  Copyright 2009 MPI Cognitive and Human Brain Sciences Leipzig. All rights reserved.
//

#import "BAProcedureController.h"
#import "BADataElement.h"
#import "BADesignElement.h"
#import "BAAnalyzerElement.h"
#import "BADataElementRealTimeLoader.h"
#import "BARTNotifications.h"
#import "../CLETUS/COSystemConfig.h"


@interface BAProcedureController ()

//
BADataElement *mInputData;
BADesignElement *mDesignData;
BADataElement *mResultData;
BAAnalyzerElement *mAnalyzer;
size_t mCurrentTimestep;
BADataElementRealTimeLoader *mRtLoader;
COSystemConfig *config;
//TODO: define enum and take a switch where needed
BOOL isRealTimeTCPInput;
// isRealTimeFileInput;
// isDemoFileInput;
size_t startAnalysisAtTimeStep;



-(void)nextDataArrived:(NSNotification*)aNotification;
-(void)analysisStepDidFinish:(NSNotification*)aNotification;

-(void)processDataThread;
-(void)timerThread;



@end


@implementation BAProcedureController

-(id)init
{
    if (self = [super init]) {
        // TODO: appropriate init
        mCurrentTimestep = 0;
		//justatest = [[BADataElement alloc ] initEmptyWithSize:[[BARTImageSize alloc] init] ofImageType:IMAGE_ZMAP];
		 config = [COSystemConfig getInstance];
		isRealTimeTCPInput = TRUE;
		startAnalysisAtTimeStep = 15;
    }
    return self;
}

-(void)dealloc
{
	
	[mInputData release];
	[mResultData release];
    [mDesignData release];
	[mAnalyzer release];
	
	
	[super dealloc];
}


-(BOOL) initData
{
	// release actual data element
	if (nil != mInputData){
		[mInputData release];
		mInputData = nil;
	}
	//TODO: switch for different versions!!
	//FILE LOAD STUFF
	if (FALSE == isRealTimeTCPInput){
		// setup the input data
		mInputData = [[BADataElement alloc] initWithDataFile:@"../../tests/BARTMainAppTests/testfiles/TestDataset02-functional.nii" andSuffix:@"" andDialect:@"" ofImageType:IMAGE_FCTDATA];
		if (nil == mInputData) {
			return FALSE;
		}
		//POST 
	
		[[NSNotificationCenter defaultCenter] postNotificationName:BARTDidLoadBackgroundImageNotification object:mInputData];
	}
	else{
		//REALTIMESTUFF
		//TODO: Unterscheidung Verzeichnis laden oder rtExport laden - zweiter RealTimeLoader
		mRtLoader = [[BADataElementRealTimeLoader alloc] init];
		//BARTImageSize *imSize = [[BARTImageSize alloc] init];
		//mInputData = [[BADataElement alloc] initForRealTimeTCPIPWithSize:imSize ofImageType:IMAGE_FCTDATA];
		//register as observer for new data
		[[NSNotificationCenter defaultCenter] addObserver:self 
												 selector:@selector(nextDataArrived:)
													 name:BARTDidLoadNextDataNotification object:nil];
		
		
	}
	
	
	return TRUE;
}

-(BOOL) initDesign
{
	if (nil != mDesignData){
		[mDesignData release];
		mDesignData = nil;}
	
	mDesignData = [[BADesignElement alloc] initWithDynamicDataOfImageDataType:IMAGE_DATA_FLOAT];
	if (nil == mDesignData){
		return FALSE;}
	
	return TRUE;
}

-(BOOL) initPresentation
{
	return FALSE;
}

-(BOOL) initAnalyzer
{
	if (nil != mAnalyzer){
		[mAnalyzer release];
		mAnalyzer = nil;}
	
	mAnalyzer = [[BAAnalyzerElement alloc] initWithAnalyzerType:kAnalyzerGLM];
	if (nil == mAnalyzer){
		return FALSE;}
	return TRUE;
}

-(BOOL)startAnalysis
{
	if (FALSE == isRealTimeTCPInput){
		[NSThread detachNewThreadSelector:@selector(timerThread) toTarget:self withObject:nil];}
	else {
		NSError *err = [[NSError alloc] init];
		NSThread *t = [[NSThread alloc] initWithTarget:mRtLoader selector:@selector(startRealTimeInputOfImageType) object:err]; //TODO error object 
		[t start];
	}

	return TRUE;
}

-(void)nextDataArrived:(NSNotification*)aNotification
{
	
	
	if (FALSE == isRealTimeTCPInput){
		NSLog(@"Timestep: %d", mCurrentTimestep+1);
		if ((mCurrentTimestep > startAnalysisAtTimeStep-1 ) && (mCurrentTimestep < [mDesignData mNumberTimesteps])) {
			[NSThread detachNewThreadSelector:@selector(processDataThread) toTarget:self withObject:nil];
		}
		mCurrentTimestep++;
		
		//JUST FOR TEST
		NSString *fname =[NSString stringWithFormat:@"/tmp/test_imagenr_%d.nii", mCurrentTimestep];
		[[aNotification object] WriteDataElementToFile:fname];
	}
	else {
		//get data to analyse out of notification
		mInputData = [aNotification object];
		
		NSLog(@"Nr of Timesteps in InputData: %d", [mInputData getImageSize].timesteps);
		if (([mInputData getImageSize].timesteps > startAnalysisAtTimeStep-1 ) && ([mInputData getImageSize].timesteps < [mDesignData mNumberTimesteps])) {
			[NSThread detachNewThreadSelector:@selector(processDataThread) toTarget:self withObject:nil];
		}
		// JUST FOR TEST
		NSString *fname =[NSString stringWithFormat:@"/tmp/test_imagenr_%d.nii", [mInputData getImageSize].timesteps];
		[[aNotification object] WriteDataElementToFile:fname];
	}
}

-(void)processDataThread
{
	NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	BADataElement *resData;
	
	if (FALSE == isRealTimeTCPInput){
		 resData = [mAnalyzer anaylzeTheData:mInputData withDesign:[mDesignData copy] andCurrentTimestep:mCurrentTimestep-1];
	}
	else {
		resData = [mAnalyzer anaylzeTheData:mInputData withDesign:[mDesignData copy] andCurrentTimestep:[mInputData getImageSize].timesteps];
		NSString *fname =[NSString stringWithFormat:@"/tmp/test_zmapnr_%d.nii", [mInputData getImageSize].timesteps];
		[resData WriteDataElementToFile:fname];
	}

	[[NSNotificationCenter defaultCenter] postNotificationName:BARTDidCalcNextResultNotification object:[resData retain]];

	[autoreleasePool drain];
	[NSThread exit];
}

-(void)timerThread
{
	NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	
	[self nextDataArrived:nil];
	
	[NSThread sleepForTimeInterval:1.0];
	[NSThread detachNewThreadSelector:@selector(timerThread) toTarget:self withObject:nil];
	
	[autoreleasePool drain];
	[NSThread exit];
}

-(void)analysisStepDidFinish:(NSNotification*)aNotification
{
	// TODO: update GUI
}


@end
