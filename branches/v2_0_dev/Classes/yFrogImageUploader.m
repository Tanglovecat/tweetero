// Copyright (c) 2009 Imageshack Corp.
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
// 3. The name of the author may not be used to endorse or promote products
//    derived from this software without specific prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
// IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
// OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
// IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
// NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
// THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// 

#import "yFrogImageUploader.h"
#import "TweetterAppDelegate.h"
#import "MGTwitterEngineFactory.h"
#import "LocationManager.h"
#include "util.h"

#define		JPEG_CONTENT_TYPE			@"image/jpeg"
#define		MP4_CONTENT_TYPE			@"video/mp4"

@implementation ImageUploader

@synthesize connection;
@synthesize contentXMLProperty;
@synthesize newURL;
@synthesize userData;
@synthesize delegate;
@synthesize contentType;

-(id)init
{
	self = [super init];
	if(self)
	{
		result = [[NSMutableData alloc] initWithCapacity:128];
		canceled = NO;
		scaleIfNeed = NO;
	}
	return self;
}

- (void)setVideoUploadEngine:(ISVideoUploadEngine*)engine
{
    if (videoUploadEngine != engine)
    {
        //stop and release current upload process if current is exists
        if (videoUploadEngine)
        {
            [videoUploadEngine cancel];
            [videoUploadEngine release];
        }
        //set new ISVideoUploadEngine object
        videoUploadEngine = [engine retain];
    }
}
/*
- (id)retain
{
	return [super retain];
}
- (oneway void)release
{
	[super release];
}

- (id)autorelease
{
	return [super autorelease];
}
*/

-(void)dealloc
{
    //[self setVideoUploadEngine:nil];
    [videoUploadEngine release];
	self.delegate = nil;
	self.connection = nil;
	self.contentXMLProperty = nil;
	self.newURL = nil;
	self.userData = nil;
	self.contentType = nil;
	[result  release];
	[super dealloc];
}

- (void) postData:(NSData*)data
{
	if(canceled)
		return;
		
	if(!self.contentType)
	{
		NSLog(@"Content-Type header was not setted\n");
		return;
	}
	
	//NSString* login = [MGTwitterEngine username];
	//NSString* pass = [MGTwitterEngine password];
	
    UserAccount *account = [[AccountManager manager] loggedUserAccount];
    
    MGTwitterEngineFactory *factory = [MGTwitterEngineFactory factory];
    
    NSDictionary *authFields = [factory createTwitterAuthorizationFields:account];
    
    //return;//DEBUG
    if (authFields == nil) {
		[delegate uploadedImage:nil sender:self];
        return;
    }
    
	//NSString* login = [account username];
	//NSString* pass = @"";//[MGTwitterEngine password];
    
    //NSLog([[[AccountManager manager] loggedUserAccount] secretData]);
    
	NSString *boundary = [NSString stringWithFormat:@"------%ld__%ld__%ld", random(), random(), random()];
	
	NSURL *url = [NSURL URLWithString:@"http://yfrog.com/api/upload"];
    
    //NSURL *url = [NSURL URLWithString:@"http://img643.yfrog.com/yfrog/api_impl.php?action=upload"];
    
	NSMutableURLRequest *req = tweeteroMutableURLRequest(url);
	[req setHTTPMethod:@"POST"];

	NSString *multipartContentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
	[req setValue:multipartContentType forHTTPHeaderField:@"Content-type"];
	
	//adding the body:
	NSMutableData *postBody = [NSMutableData data];
	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	[postBody appendData:[@"Content-Disposition: form-data; name=\"media\"; filename=\"iPhoneMedia\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n", self.contentType] dataUsingEncoding:NSUTF8StringEncoding]];
//	[postBody appendData:[@"Content-Type: image/jpeg\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[@"Content-Transfer-Encoding: binary\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:data];
	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	//[postBody appendData:[@"Content-Disposition: form-data; name=\"username\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	//[postBody appendData:[login dataUsingEncoding:NSUTF8StringEncoding]];
	//[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	//[postBody appendData:[@"Content-Disposition: form-data; name=\"password\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	//[postBody appendData:[pass dataUsingEncoding:NSUTF8StringEncoding]];
	
    for (NSString *key in [authFields allKeys]) {
        NSString *value = [authFields objectForKey:key];
        
        //NSLog(@"Key: %@, Value: %@", key, value);
        [postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
        [postBody appendData:[value dataUsingEncoding:NSUTF8StringEncoding]];
        [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    }

    //return;    //DEBUG
	if([[LocationManager locationManager] locationDefined])
	{
		//[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		
		[postBody appendData:[@"Content-Disposition: form-data; name=\"tags\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
		[postBody appendData:[[NSString stringWithFormat:@"geotagged, geo:lat=%+.6f, geo:lon=%+.6f", [[LocationManager locationManager] latitude], [[LocationManager locationManager] longitude]] dataUsingEncoding:NSUTF8StringEncoding]];
        [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	}

	//[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[req setHTTPBody:postBody];

    [delegate uploadedDataSize:[postBody length]];
	
	self.connection = [[[NSURLConnection alloc] initWithRequest:req delegate:self startImmediately:YES] autorelease];
	if (!self.connection) 
	{
		[delegate uploadedImage:nil sender:self];
	}
	
	[TweetterAppDelegate increaseNetworkActivityIndicator];
}

- (void) postData:(NSData*)data contentType:(NSString*)mediaContentType
{
	self.contentType = mediaContentType;
	[self postData:data];
}


- (void)postJPEGData:(NSData*)imageJPEGData delegate:(id <ImageUploaderDelegate>)dlgt userData:(id)data
{
	self.delegate = dlgt;
	self.userData = data;
	
	if(!imageJPEGData)
	{
		[delegate uploadedImage:nil sender:self];
		return;
	}

	[self postData:imageJPEGData contentType:JPEG_CONTENT_TYPE];
}

- (void)postMP4DataWithUploadEngine:(ISVideoUploadEngine*)engine delegate:(id <ImageUploaderDelegate>)dlgt userData:(id)data
{
	self.delegate = dlgt;
	self.userData = data;
	[TweetterAppDelegate increaseNetworkActivityIndicator];
    
    UserAccount *account = [[AccountManager manager] loggedUserAccount];
    MGTwitterEngineFactory *factory = [MGTwitterEngineFactory factory];
    NSDictionary *authFields = [factory createTwitterAuthorizationFields:account];
    if (authFields) {
        NSString *val = [authFields objectForKey:@"username"];
        if (val)
            engine.username = val;
        val = [authFields objectForKey:@"password"];
        if (val)
            engine.password = val;
        else {
            val = [authFields objectForKey:@"verify_url"];
            if (val)
                engine.verifyUrl = val;
        }
    }
    if (![engine upload])
        [delegate uploadedImage:nil sender:self];
    else
        [self setVideoUploadEngine:engine];
}

- (void)postMP4DataWithPath:(NSString*)path delegate:(id <ImageUploaderDelegate>)dlgt userData:(id)data
{
	if(!path)
	{
		[delegate uploadedImage:nil sender:self];
		return;
	}
	
#ifdef TRACE
	NSLog(@"YFrog_DEBUG: Executing postMP4DataWithPath:delegate: method...");
	NSLog(@"	YFrog_DEBUG: Creating Video upload engine");
#endif
	
    ISVideoUploadEngine *engine = [[ISVideoUploadEngine alloc] initWithPath:path delegate:self];
    [self postMP4DataWithUploadEngine:engine delegate:dlgt userData:data];
    [engine release];
}

- (void)postMP4Data:(NSData*)movieData delegate:(id <ImageUploaderDelegate>)dlgt userData:(id)data
{
	if(!movieData)
	{
		[delegate uploadedImage:nil sender:self];
		return;
	}
    ISVideoUploadEngine *engine = [[ISVideoUploadEngine alloc] initWithData:movieData delegate:self];
    [self postMP4DataWithUploadEngine:engine delegate:dlgt userData:data];
    [engine release];
}

- (void)convertImageThreadAndStartUpload:(UIImage*)image
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSData* imData = UIImageJPEGRepresentation(image, 1.0f);
	self.contentType = JPEG_CONTENT_TYPE;
	[self performSelectorOnMainThread:@selector(postData:) withObject:imData waitUntilDone:NO];

	[pool release];
}

- (void)postImage:(UIImage*)image delegate:(id <ImageUploaderDelegate>)dlgt userData:(id)data
{
	self.delegate = dlgt;
	self.userData = data;

	UIImage* modifiedImage = nil;
	
	BOOL needToResize;
	BOOL needToRotate;
	int newDimension = isImageNeedToConvert(image, &needToResize, &needToRotate);
	if(needToResize || needToRotate)		
		modifiedImage = imageScaledToSize(image, newDimension);

	[NSThread detachNewThreadSelector:@selector(convertImageThreadAndStartUpload:) toTarget:self withObject:modifiedImage ? modifiedImage : image];
}

#pragma mark NSURLConnection delegate methods


- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [result setLength:0];
}


- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [result appendData:data];
}


- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	[TweetterAppDelegate decreaseNetworkActivityIndicator];
	[delegate uploadedImage:nil sender:self];
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten 
                                      totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    [delegate uploadedProccess:bytesWritten totalBytesWritten:totalBytesWritten];
}

- (NSCachedURLResponse *) connection:(NSURLConnection *)connection 
                   willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
     return cachedResponse;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if (qName) 
        elementName = qName;

    if ([elementName isEqualToString:@"mediaurl"])
		self.contentXMLProperty = [NSMutableString string];
	else
		self.contentXMLProperty = nil;
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{     
    if (qName)
        elementName = qName;
    
    if ([elementName isEqualToString:@"mediaurl"])
	{
        self.newURL = [self.contentXMLProperty stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		[parser abortParsing];
	}
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    if (self.contentXMLProperty)
		[self.contentXMLProperty appendString:string];
}


- (void) connectionDidFinishLoading:(NSURLConnection *)connection
{
	[TweetterAppDelegate decreaseNetworkActivityIndicator];
    
	NSXMLParser *parser = [[NSXMLParser alloc] initWithData:result];
	[parser setDelegate:self];
	[parser setShouldProcessNamespaces:NO];
	[parser setShouldReportNamespacePrefixes:NO];
	[parser setShouldResolveExternalEntities:NO];
	[parser parse];
	[parser release];
    
	[result setLength:0];
	[delegate uploadedImage:self.newURL sender:self];
}

- (void)cancel
{
	canceled = YES;
	if(connection)
	{
		[connection cancel];
		[TweetterAppDelegate decreaseNetworkActivityIndicator];
	}
	[self setVideoUploadEngine:nil];
	[delegate uploadedImage:nil sender:self];
}

- (BOOL)canceled
{
	return canceled;
}

#pragma mark ISVideoUploadEngine Delegate
- (void)didStartUploading:(ISVideoUploadEngine *)engine totalSize:(NSUInteger)size
{
    [delegate uploadedDataSize:size];
}

- (void)didFinishUploading:(ISVideoUploadEngine *)engine videoUrl:(NSString *)link
{
	[TweetterAppDelegate decreaseNetworkActivityIndicator];
	[delegate uploadedImage:link sender:self];
}

- (void)didFailWithErrorMessage:(ISVideoUploadEngine *)engine errorMessage:(NSString *)error
{
	[TweetterAppDelegate decreaseNetworkActivityIndicator];
	[delegate uploadedImage:nil sender:self];
}

- (void)didFinishUploadingChunck:(ISVideoUploadEngine *)engine uploadedSize:(NSUInteger)totalUploadedSize totalSize:(NSUInteger)size
{
    [delegate uploadedProccess:totalUploadedSize totalBytesWritten:totalUploadedSize];
}

- (void)didStopUploading:(ISVideoUploadEngine *)engine
{
}

- (void)didResumeUploading:(ISVideoUploadEngine *)engine
{
}

@end