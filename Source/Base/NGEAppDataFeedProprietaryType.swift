import Foundation

#if (arch(i386) || arch(x86_64)) && os(iOS)
import libxmlSimu
#else
import libxml
#endif

@objc
class NGEAppDataFeedProprietaryType : NSObject{
    
    var `category`: String!
    
    var `feedType`: String!
    
    var `feedSubType`: String?
    
    var `SourceURL`: String?
    
    var `QueryObject`: String?
    
    func readAttributes(_ reader: xmlTextReaderPtr) {
        
        if let attrValue = xmlTextReaderGetAttribute(reader, "category") {
            
            self.category = String(cString: attrValue)
            xmlFree(attrValue)
        }
        if let attrValue = xmlTextReaderGetAttribute(reader, "feedType") {
            
            self.feedType = String(cString: attrValue)
            xmlFree(attrValue)
        }
        if let attrValue = xmlTextReaderGetAttribute(reader, "feedSubType") {
            
            self.feedSubType = String(cString: attrValue)
            xmlFree(attrValue)
        }
    }
    
    init(_ reader: xmlTextReaderPtr) {
        let _complexTypeXmlDept = xmlTextReaderDepth(reader)
        super.init()
        
        self.readAttributes(reader)
        
        var _readerOk = xmlTextReaderRead(reader)
        var _currentNodeType = xmlTextReaderNodeType(reader)
        var _currentXmlDept = xmlTextReaderDepth(reader)
        
        while(_readerOk > 0 && _currentNodeType != 0/*XML_READER_TYPE_NONE*/ && _complexTypeXmlDept < _currentXmlDept) {
            
            if(_currentNodeType == 1/*XML_READER_TYPE_ELEMENT*/ || _currentNodeType == 3/*XML_READER_TYPE_TEXT*/) {
                if let _currentElementNameXmlChar = xmlTextReaderConstLocalName(reader) {
                    let _currentElementName = String(cString: _currentElementNameXmlChar)
                    if("SourceURL" == _currentElementName) {
                        
                        _readerOk = xmlTextReaderRead(reader)
                        _currentNodeType = xmlTextReaderNodeType(reader)
                        if let elementValue = xmlTextReaderConstValue(reader) {
                            
                            self.SourceURL = String(cString: elementValue)
                            
                        }
                        _readerOk = xmlTextReaderRead(reader)
                        _currentNodeType = xmlTextReaderNodeType(reader)
                        
                    } else if("QueryObject" == _currentElementName) {
                        
                        _readerOk = xmlTextReaderRead(reader)
                        _currentNodeType = xmlTextReaderNodeType(reader)
                        if let elementValue = xmlTextReaderConstValue(reader) {
                            
                            self.QueryObject = String(cString: elementValue)
                            
                        }
                        _readerOk = xmlTextReaderRead(reader)
                        _currentNodeType = xmlTextReaderNodeType(reader)
                        
                    } else   if(true) {
                        print("Ignoring unexpected in NGEAppDataFeedProprietaryType: \(_currentElementName)")
                        if superclass != NSObject.self {
                            break
                        }
                    }
                }
            }
            _readerOk = xmlTextReaderRead(reader)
            _currentNodeType = xmlTextReaderNodeType(reader)
            _currentXmlDept = xmlTextReaderDepth(reader)
        }
        
    }
    
}

