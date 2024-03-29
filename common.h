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

// common.h

// This file contains prototypes for functions to perform general purpose
// XML node text extraction and to process the shared meta.xml file format
// that is common to all OOo file types.

// Planamesa, Inc.
// 4/27/05

#ifndef COMMON_H_

#define COMMON_H_

#import <Foundation/Foundation.h>

/**
 * Default capacity for NSMutableData instances
 */
#define kFileUnzipCapacity          32768

/**
  * Default capacity for NSMutableString instances
  */
#define kTextExtractionCapacity     1024

/**
 * Given a path to a zip archive, extract the content of an individual file
 * of that zip archive into a mutable data structure.
 *
 * The file is attempted to be extracted using UTF8 encoding.
 *
 * @param pathToArhive		path to the zip archive on disk
 * @param fileToExtract		file from the archive that should be extracted
 * @param fileContents		mutable data that should be filled with the
 *				contents of that subfile.    File content
 *				will be appended onto any preexisting data
 *				already in the ref.
 * @return noErr on success, else OS error code
 */
OSErr ExtractZipArchiveContent(CFStringRef pathToArchive, const char *fileToExtract, NSMutableData *fileContents);

/**
 * Given the content of a meta.xml document stored in a NSData object, extract
 * relevant metadata into a spotlight dictionary.
 */
void ParseMetaXML(NSData *contentNSData, CFMutableDictionaryRef spotlightDict);

/**
 * Given a node of a CoreFoundation XML structure, extracxt any
 * text content from that node or recurse on the node's children as
 * appropriate.
 *
 * The text data is attempted to be extracted with UTF8 encoding, in
 * internal representation (no byte ordering marker)
 *
 * @param elementPrefix	element tag names are examined for this prefix.  When
 *			encountered, all text data child nodes will have their
 *			content concatenated onto the mutable data
 * @param xmlTreeNode	current tree representation of the node being parsed
 * @param textData	when the first element is found with the given prefix,
 *			all of the child text nodes of that element will
 *			have their content appended onto this mutable data
 *			elemnet.
 * @param separatorChar	UTF8 character used to separate consecutive text nodes in
 *			the metadata
 * @param saveText	true to save NSData node content as text, FALSE to just
 *			recurse into element children
 */
void ExtractNodeText(CFStringRef elementPrefix, NSXMLNode *xmlTreeNode, NSMutableString *textData, NSString *separatorString=@" ", bool saveText=false);

/**
 * Given a node of a CoreFoundation XML structure, extracxt any
 * text content from attributes of that node.
 *
 * The text data is attempted to be extracted with UTF8 encoding, in
 * internal representation (no byte ordering marker)
 *
 * @param elementPrefix	element tag names are examined for this prefix.  When
 *			encountered, all of these nodes will have their attributes examined
 * @param attributeName	name of the attribute whose value should be extracted
 * @param xmlTreeNode	current tree representation of the node being parsed
 * @param textData	when elements are found with the given elementPrefix, any
 *					attribute with the specified name will have its value
 *					appended to the end of this mutable data, along with a
 *					the separatorChar separator
 * @param separatorChar	UTF8 character used to separate consecutive attribute values in
 *			the metadata
 */
void ExtractNodeAttributeValue(CFStringRef elementPrefix, CFStringRef attributeName, NSXMLNode *xmlTreeNode, NSMutableString *textData, NSString *separatorString=@" ");

/**
 * Parse a styles.xml file of an OOo formatted file into for spotlight to index
 * header and footer content
 *
 * @param styleNSData		XML file with styles.xml extaction
 * @param spotlightDict		spotlight dictionary to be filled wih the text content
 */
void ParseStylesXML(NSData *styleNSData, CFMutableDictionaryRef spotlightDict);

#endif
