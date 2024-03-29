/* -*- Mode: C++; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- */
/*
 * This file is part of the LibreOffice project.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 *
 * This file incorporates work covered by the following license notice:
 *
 *   Licensed to the Apache Software Foundation (ASF) under one or more
 *   contributor license agreements. See the NOTICE file distributed
 *   with this work for additional information regarding copyright
 *   ownership. The ASF licenses this file to you under the Apache
 *   License, Version 2.0 (the "License"); you may not use this file
 *   except in compliance with the License. You may obtain a copy of
 *   the License at http://www.apache.org/licenses/LICENSE-2.0 .
 */

// impress.mm

// Process an OOo 1.1 formatted SXI impress file to extract metadata for spotlight
// indexing.  Will also function for draw files containing embedded text
// elements.

// Planamesa, Inc.
// 4/27/05

#include "impress.h"
#include "common.h"
#include <CoreServices/CoreServices.h>

///// constants /////

/**
 * Subfile in an SXI archive indicating the OOo metadata
 */
#define kImpressMetadataArchiveFile	"meta.xml"

/**
 * Subfile in an SXI archive holding the presentation content
 */
#define kImpressContentArchiveFile		"content.xml"

/**
 * Subfile in an SXI archive holding the style content
 */
#define kImpressStylesArchiveFile		"styles.xml"

///// prototypes /////

static void ParseImpressContentXML(NSData *contentNSData, CFMutableDictionaryRef spotlightDict);

///// functions /////

/**
 * Extract metadata from OOo Impress files.  This adds the OOo formatted metadata
 * as well as content of presentation nodes of the presentation.
 *
 * @param pathToFile	path to the sxi file that should be parsed.  It is
 *			assumed the caller has verified the type of this file.
 * @param spotlightDict	dictionary to be filled with Spotlight attributes
 *			for file metadata
 * @return noErr on success, else OS error code
 * @author ed
 */
OSErr ExtractImpressMetadata(CFStringRef pathToFile, CFMutableDictionaryRef spotlightDict)
{
    OSErr theErr = -50;
    
    if(!pathToFile || !spotlightDict)
        return(theErr);
    
	// open the "meta.xml" file living within the sxi and read it into
	// the spotlight dictionary
	
    NSMutableData *metaNSData=[NSMutableData dataWithCapacity:kFileUnzipCapacity];
	theErr=ExtractZipArchiveContent(pathToFile, kImpressMetadataArchiveFile, metaNSData);
    if(theErr!=noErr)
		return(theErr);
	ParseMetaXML(metaNSData, spotlightDict);
	
	// open the "content.xml" file within the sxi and extract its text
	
    NSMutableData *contentNSData=[NSMutableData dataWithCapacity:kFileUnzipCapacity];
    theErr=ExtractZipArchiveContent(pathToFile, kImpressContentArchiveFile, contentNSData);
	if(theErr!=noErr)
		return(theErr);
	ParseImpressContentXML(contentNSData, spotlightDict);
	
	// open the "styles.xml" file and extract any header and footer
	
	NSMutableData *stylesNSData=[NSMutableData dataWithCapacity:kFileUnzipCapacity];
	theErr=ExtractZipArchiveContent(pathToFile, kImpressStylesArchiveFile, stylesNSData);
	if(theErr!=noErr)
		return(theErr);
	ParseStylesXML(stylesNSData, spotlightDict);
    
	return(noErr);
}

/**
 * Parse the content of a SXI file.  This places the content of outlines and
 * other text elements of the presentation into the CFText metadata item.
 *
 * @param contentNSData		XML file with content.xml extaction
 * @param spotlightDict		spotlight dictionary to be filled wih the text content
 */
static void ParseImpressContentXML(NSData *contentNSData, CFMutableDictionaryRef spotlightDict)
{
	if(!contentNSData || ![contentNSData length] || !spotlightDict)
		return;
	
	// instantiate an XML parser on the content.xml file
	
    NSXMLDocument *xmlTree = [[NSXMLDocument alloc] initWithData:contentNSData options:NSXMLNodeOptionsNone error:nil];
    if(!xmlTree)
        return;
    
    [xmlTree autorelease];
    
    NSMutableString *textData=[NSMutableString stringWithCapacity:kTextExtractionCapacity];
    if (!textData)
        return;
    
	// SXI files use elements of draw:text-box to hold all of its titles,
	// outlines, and other textual information.  Extract their text
	// content into the text content for spotlight indexing.
	
	ExtractNodeText(CFSTR("draw:text-box"), xmlTree, textData);
	
	// add the data as a text node for spotlight indexing
	
    if([textData length])
    {
        CFStringRef previousText=(CFStringRef)CFDictionaryGetValue(spotlightDict, kMDItemTextContent);
        if(previousText)
        {
            // append this text to the existing set
            if(CFStringGetLength(previousText))
            {
                [textData insertString:@" " atIndex:0];
                [textData insertString:(NSString *)previousText atIndex:0];
            }
            CFDictionaryReplaceValue(spotlightDict, kMDItemTextContent, (CFStringRef)textData);
        }
        else
        {
            CFDictionaryAddValue(spotlightDict, kMDItemTextContent, (CFStringRef)textData);
        }
    }
}
