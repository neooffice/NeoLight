/*************************************************************************
 *
 *  $RCSfile$
 *
 *  $Revision$
 *
 *  last change: $Author$ $Date$
 *
 *  The Contents of this file are made available subject to the terms of
 *  either of the following licenses
 *
 *         - GNU General Public License Version 2.1
 *
 *  Planamesa, Inc., 2005-2007
 *
 *  GNU General Public License Version 2.1
 *  =============================================
 *  Copyright 2005-2007 by Planamesa, Inc. (OPENSTEP@neooffice.org)
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU General Public
 *  License version 2.1, as published by the Free Software Foundation.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public
 *  License along with this library; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston,
 *  MA  02111-1307  USA
 *
 ************************************************************************/

// base.mm

// Process an OpenDocument database file to extract data for Spotlight
// indexing

// Planamesa, Inc.
// 9/24/06

#include "base.h"
#include "common.h"
#include <CoreServices/CoreServices.h>

///// constants /////
/**
 * Subfile in an odb archive indicating the OOo metadata
 */
#define kBaseMetadataArchiveFile	"meta.xml"

/**
 * Subfile in an odb archive holding the table content
 */
#define kBaseContentArchiveFile		"content.xml"

///// prototypes /////

static void ParseBaseContentXML(NSData *contentNSData, CFMutableDictionaryRef spotlightDict);

///// functions /////

/**
 * Extract metadata from OOo Base files.  This adds the OOo formatted metadata
 * from the base file.
 *
 * @param pathToFile	path to the odb file that should be parsed.  It is
 *			assumed the caller has verified the type of this file.
 * @param spotlightDict	dictionary to be filled with Spotlight attributes
 *			for file metadata
 * @return noErr on success, else OS error code
 * @author ed
 */
OSErr ExtractBaseMetadata(CFStringRef pathToFile, CFMutableDictionaryRef spotlightDict)
{
    OSErr theErr = -50;
    
    if(!pathToFile || !spotlightDict)
        return(theErr);
        
	// open the "meta.xml" file living within the sxc and read it into
	// the spotlight dictionary
	
    NSMutableData *metaNSData=[NSMutableData dataWithCapacity:kFileUnzipCapacity];
	theErr=ExtractZipArchiveContent(pathToFile, kBaseMetadataArchiveFile, metaNSData);
	if(theErr==noErr)
		ParseMetaXML(metaNSData, spotlightDict);
    
	// note unlike other OpenDocument files, Base files seem to not consistently have a
	// meta document for them!  So let's continue to try to index regardless
    
	// open the "content.xml" file within the sxc and extract its text
	
	NSMutableData *contentNSData=[NSMutableData dataWithCapacity:kFileUnzipCapacity];
	theErr=ExtractZipArchiveContent(pathToFile, kBaseContentArchiveFile, contentNSData);
	if(theErr!=noErr)
		return(theErr);
	ParseBaseContentXML(contentNSData, spotlightDict);
    
	return(noErr);
}

/**
 * Parse the content of an odb file.
 *
 * @param contentNSData		XML file with content.xml extaction
 * @param spotlightDict		spotlight dictionary to be filled wih the text content
 */
static void ParseBaseContentXML(NSData *contentNSData, CFMutableDictionaryRef spotlightDict)
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
    
	// odb file content contains lists of table names and form names.  This information is stored in attributes
	// of the relevant nodes in the man content.xml file.
	
	// grab form names
	ExtractNodeAttributeValue(CFSTR("db:component"), CFSTR("db:name"), xmlTree, textData);
	
	// grab table names
	ExtractNodeAttributeValue(CFSTR("db:table"), CFSTR("db:name"), xmlTree, textData);
	
	// grab column names
	ExtractNodeAttributeValue(CFSTR("db:column"), CFSTR("db:name"), xmlTree, textData);
	
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
