// /////////////////////////////////////////
// --------- Original Article -------------
// https://medium.com/rocknnull/ios-to-swizzle-or-not-to-swizzle-f8b0ed4a1ce6?_branch_match_id=440752107783156620
// /////////////////////////////////////////

#import <WebKit/WebKit.h>
// We need to import the objc runtime to perfom swizzling
#import <objc/runtime.h>


// Note that you need to write "@implementation WKWebView (Cookie)"
// and not just "@implementation WKWebView"
// It is call category in objective C
// Read more here
// https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/CustomizingExistingClasses/CustomizingExistingClasses.html
@implementation WKWebView (Cookie)

// The following function is the glue that perform the swizzling
// (think monkey patching while keeping a reference to the old method so the new method can just extends the old method)
+ (void)load {
  static dispatch_once_t onceToken;
  // Here we ensure that the swizzling is done only once
  // This is thread safe
  // That is not necessary in swift as we would use static function for this, that are lazy by default
  dispatch_once(&onceToken, ^{
    // We get the class of the instance
    // so we can apply the selector later
    Class class = [self class];
    
    // Lets select the original request and the modified one
    // (defined on the "Method Swizzling" section in this precise file)
    // Selector are like SQL queries "where" part. It define what to select but not from what class.
    //
    // Note that objective C is weird.
    // "loadRequest" is a function with no argument
    // "loadRequest:" (note the trailing ":") is a function with one argument
    // "loadRequest:secondArg:" is a function with two argument. Weird.
    SEL originalSelector = @selector(loadRequest:);
    SEL swizzledSelector = @selector(swizzled_loadRequest:);
    
    // We then execute the selector ("where") in the class ("from") for both original and swizzled
    Method defaultMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    
    // We now have two cases:
    // 1) The swizzled selector already exist in the dispatch table (which can happen for instance if you call WKWebKit.swizeled_loadRequest
    // 2) The swizzled selector does not yet exists
    //
    // Objective C is a weird language, when we call a method we send a msg some listener that call the implementation
    // Think of a weird mix between Javascript prototypal inheritance and elrang messaging system, while beeing less clear than both
    // Here is some documentation: https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtHowMessagingWorks.html
    // DON'T READ IT
    
    // This will add the swizzled implementation and swizzled types if the swizzeled method does not exist and return true (success).
    // If the method does not exist, it will fail and return false, hence setting the "doesMethodExists" to true
    BOOL doesMethodExists = !class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
    
    if (doesMethodExists) {
      // We exchange the implementation of the methods
      method_exchangeImplementations(defaultMethod, swizzledMethod);
    }
    else {
      // If the method was not existing, the originalSelector now points to the swizzled implementation already
      // So we only have to make the swizzledSelector points to the original one
      class_replaceMethod(class, swizzledSelector, method_getImplementation(defaultMethod), method_getTypeEncoding(defaultMethod));
    }
  });
}

#pragma mark - Method Swizzling
// Here the implementation we want to use instead of the loadRequest one
- (nullable WKNavigation *)swizzled_loadRequest:(NSURLRequest *)request {
  // We can add some stuff
  NSLog(@"Swizzling visit Source");
  // or do actually usefull stuff like storing the cookie from the request
  // and so on
  // feel free to be inventive here, it is the best occasion to write some GOOD objective C
  
  // And then we call (like "super()" in python or any good/classic OO language) the original method
  // The original method is already exchange with swizzled so it looks weird but it works
  return [self swizzled_loadRequest:request];
}

@end
