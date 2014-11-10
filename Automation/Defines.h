//
//  Defines.h
//  Automation
//
//  Created by Scott Gruby on 10/5/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

#ifndef Automation_Defines_h
#define Automation_Defines_h

#ifdef INFO_PLIST
#define STRINGIFY(_x)        _x
#else
#define STRINGIFY(_x)      # _x
#endif

#define STRX(x)			x

#define APP_VERSION_NUMBER				STRINGIFY(1.0.0)
#define CF_BUNDLE_VERSION				STRINGIFY(2)


#endif
