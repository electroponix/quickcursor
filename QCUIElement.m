//
//  QCUIElement.m
//  QuickCursor
//
//  Created by Jesse Grosjean on 11/28/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "QCUIElement.h"


@implementation QCUIElement

#pragma mark Class Methods

// kAXValueChangedNotification
// kAXUIElementDestroyedNotification

+ (QCUIElement *)systemWideElement {
	static QCUIElement* systemWideQCUIElement = nil;
	if (!systemWideQCUIElement) {
		systemWideQCUIElement = [[QCUIElement alloc] initWithAXUIElementRef:AXUIElementCreateSystemWide()];
	}
	return systemWideQCUIElement;
}

+ (QCUIElement *)focusedElement {
	return [[self systemWideElement] valueForAttribute:@"AXFocusedUIElement"];
}

#pragma mark Init

- (id)initWithAXUIElementRef:(AXUIElementRef)aUIElementRef {
	if (self = [super init]) {
		uiElementRef = CFRetain(aUIElementRef);
	}
	return self;
}

#pragma mark Attributes

- (NSString *)processName {
	pid_t theAppPID = 0;
	ProcessSerialNumber theAppPSN = {0,0};
	NSString * theAppName = NULL;
	
	if (AXUIElementGetPid(uiElementRef, &theAppPID) == kAXErrorSuccess
		&& GetProcessForPID(theAppPID, &theAppPSN) == noErr
		&& CopyProcessName(&theAppPSN, (CFStringRef *)&theAppName) == noErr) {
		return theAppName;
	}
	
	return nil;
}

- (QCUIElement *)application {
	QCUIElement *uiElement = self.topLevelUIElement;
	while (uiElement && ![[uiElement role] isEqualToString:(NSString *)kAXApplicationRole]) {
		uiElement = uiElement.parent;
	}
	return uiElement;
}

- (QCUIElement *)topLevelUIElement {
	return [self valueForAttribute:(NSString *)kAXTopLevelUIElementAttribute];
}

- (QCUIElement *)window {
	return [self valueForAttribute:(NSString *)kAXWindowAttribute];
}

- (QCUIElement *)parent {
	return [self valueForAttribute:(NSString *)kAXParentAttribute];
}

- (NSString *)title {
	return [self valueForAttribute:(NSString *)kAXTitleAttribute];
}

- (NSString *)role {
	return [self valueForAttribute:(NSString *)kAXRoleAttribute];
}

- (id)value {
	return [self valueForAttribute:(NSString *)kAXValueAttribute];
}

- (void)setValue:(id)value {
	[self setValue:value forAttribute:(NSString *)kAXValueAttribute];
}


- (NSArray *)attributeNames {
	NSArray* attributeNames;
	AXUIElementCopyAttributeNames(uiElementRef, (CFArrayRef *)&attributeNames);
	return attributeNames;
}

- (id)valueForAttribute:(NSString *)attributeName {
	CFTypeRef theValue;
	
	AXError error = AXUIElementCopyAttributeValue(uiElementRef, (CFStringRef)attributeName, &theValue);
		
	if (error != kAXErrorSuccess) {
		BLogError(@"error in AXUIElementCopyAttributeValue");
		return nil;
	}
	
	if (AXValueGetType(theValue) == kAXValueCGPointType) {
		BLogError(@"unimplemented, should not be used by QuickCursor");
	} else if (AXValueGetType(theValue) == kAXValueCGSizeType) {
		BLogError(@"unimplemented, should not be used by QuickCursor");
	} else if (AXValueGetType(theValue) == kAXValueCGRectType) {
		BLogError(@"unimplemented, should not be used by QuickCursor");
	} else if (AXValueGetType(theValue) == kAXValueCFRangeType) {
		BLogError(@"unimplemented, should not be used by QuickCursor");
	} else if (CFGetTypeID(theValue) == AXUIElementGetTypeID()) {
		return [[QCUIElement alloc] initWithAXUIElementRef:theValue];
	} else if (CFGetTypeID(theValue) == CFArrayGetTypeID()) {
		BLogError(@"unimplemented, should not be used by QuickCursor");
	} else {
		return [(id)theValue description];
	}
/*	
	if (theValue) {
        if (AXValueGetType(theValue) != kAXValueIllegalType) {
			BLogError(@"unimplemented, should not be used by QuickCursor");
		} else if (CFGetTypeID(theValue) == CFArrayGetTypeID()) {
			BLogError(@"unimplemented, should not be used by QuickCursor");
		} else if (CFGetTypeID(theValue) == AXUIElementGetTypeID()) {
			return [[QCUIElement alloc] initWithAXUIElementRef:theValue];
		} else {
			return [(id)theValue description];
		}
	}
*/	
	return nil;
}

- (BOOL)setValue:(id)newValue forAttribute:(NSString *)attributeName {
	Boolean settableFlag = false;
	
	AXUIElementIsAttributeSettable(uiElementRef, (CFStringRef)attributeName, &settableFlag);
	
	if (!settableFlag) {
		BLogWarn([NSString stringWithFormat:@"%@ is not a writeable attribute", attributeName]);
		return NO;
	}
	
	CFTypeRef theOldValue = NULL;
	CFTypeRef theNewValue = NULL;

	AXError error = AXUIElementCopyAttributeValue(uiElementRef, (CFStringRef)attributeName, &theOldValue);
	
	if (error != kAXErrorSuccess) {
		BLogError(@"error in AXUIElementCopyAttributeValue");
		return NO;
	}
	
	if (theOldValue) {
        if (AXValueGetType(theOldValue) == kAXValueCGPointType) { // CGPoint
            CGPoint point;
            theNewValue = AXValueCreate(kAXValueCGPointType, (const void *)&point);
            if (theNewValue) {
                AXUIElementSetAttributeValue(uiElementRef, (CFStringRef)attributeName, theNewValue );
                CFRelease(theNewValue);
            }
        } else if (AXValueGetType(theOldValue) == kAXValueCGSizeType) {	// CGSize
            CGSize size;
            theNewValue = AXValueCreate( kAXValueCGSizeType, (const void *)&size );
            if (theNewValue) {
                AXUIElementSetAttributeValue(uiElementRef, (CFStringRef)attributeName, theNewValue );
                CFRelease( theNewValue );
            }
        } else if (AXValueGetType(theOldValue) == kAXValueCGRectType) {	// CGRect
            CGRect rect;
            theNewValue = AXValueCreate( kAXValueCGRectType, (const void *)&rect );
            if (theNewValue) {
                AXUIElementSetAttributeValue(uiElementRef, (CFStringRef)attributeName, theNewValue );
                CFRelease( theNewValue );
            }
        } else if (AXValueGetType(theOldValue) == kAXValueCFRangeType) {	// CFRange
            CFRange range;
            theNewValue = AXValueCreate( kAXValueCFRangeType, (const void *)&range );
            if (theNewValue) {
                AXUIElementSetAttributeValue(uiElementRef, (CFStringRef)attributeName, theNewValue );
                CFRelease( theNewValue );
            }
        } else if ([(id)theOldValue isKindOfClass:[NSString class]]) { // NSString
            AXUIElementSetAttributeValue(uiElementRef, (CFStringRef)attributeName, newValue);
        } else if ([(id)theOldValue isKindOfClass:[NSValue class]]) { // NSValue
            AXUIElementSetAttributeValue(uiElementRef, (CFStringRef)attributeName, [NSNumber numberWithLong:[newValue intValue]] );
        }
	}
	
	return YES;
}

@end
