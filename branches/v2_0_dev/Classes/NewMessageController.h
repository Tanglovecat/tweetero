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

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "TwitEditorController.h"

@class MGTwitterEngine;

@interface NewMessageController : TwitEditorController
{
    NSString *_user;
}

- (id)init;
- (void)setUser:(NSString*)user;
- (NSString *)username;

@end

@interface NewMessageControllerOld : UIViewController <UITextViewDelegate> 
{
    IBOutlet UITextView *textEdit;
    IBOutlet id sendButton;
	IBOutlet id cancelButton;
	IBOutlet UILabel *charsCount;
	IBOutlet UILabel *toField;
	id _navDelegate;
	BOOL _textModified;
	MGTwitterEngine *_twitter;
	NSDictionary *_message;
    NSString *_user;
}
- (IBAction)send;
- (IBAction)cancel;

- (void)setReplyToMessage:(NSDictionary*)message;
- (void)setUser:(NSString*)user;
- (void)setRetwit:(NSString*)body whose:(NSString*)username;

- (void)textViewDidChange:(UITextView *)textView;
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text;

@end