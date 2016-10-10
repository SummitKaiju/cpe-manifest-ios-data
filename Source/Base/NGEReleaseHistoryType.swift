import Foundation

#if (arch(i386) || arch(x86_64)) && os(iOS)
import libxmlSimu
#else
import libxml
#endif

@objc
class NGEReleaseHistoryType : NSObject{
    
    var `ReleaseType`: NGEReleaseType!
    
    var `DistrTerritory`: NGERegionType?
    
    var `Date`: NGEDate!
    
    var `Description`: String?
    
    var `ReleaseOrgList`: [NGEOrgNameType]?
    
    func readAttributes(_ reader: xmlTextReaderPtr) {
        
    }
    
    init(_ reader: xmlTextReaderPtr) {
        let _complexTypeXmlDept = xmlTextReaderDepth(reader)
        super.init()
        
        self.readAttributes(reader)
        
        var ReleaseOrgListArray = [NGEOrgNameType]()
        
        var _readerOk = xmlTextReaderRead(reader)
        var _currentNodeType = xmlTextReaderNodeType(reader)
        var _currentXmlDept = xmlTextReaderDepth(reader)
        
        while(_readerOk > 0 && _currentNodeType != 0/*XML_READER_TYPE_NONE*/ && _complexTypeXmlDept < _currentXmlDept) {
            var handledInChild = false
            if(_currentNodeType == 1/*XML_READER_TYPE_ELEMENT*/ || _currentNodeType == 3/*XML_READER_TYPE_TEXT*/) {
                if let _currentElementNameXmlChar = xmlTextReaderConstLocalName(reader) {
                    let _currentElementName = String(cString: _currentElementNameXmlChar)
                    if("ReleaseType" == _currentElementName) {
                        
                        self.ReleaseType = NGEReleaseType(reader)
                        handledInChild = true
                        
                    } else if("DistrTerritory" == _currentElementName) {
                        
                        self.DistrTerritory = NGERegionType(reader)
                        handledInChild = true
                        
                    } else if("Date" == _currentElementName) {
                        
                        self.Date = NGEDate(reader)
                        handledInChild = true
                        
                    } else if("Description" == _currentElementName) {
                        
                        _readerOk = xmlTextReaderRead(reader)
                        _currentNodeType = xmlTextReaderNodeType(reader)
                        if let elementValue = xmlTextReaderConstValue(reader) {
                            
                            self.Description = String(cString: elementValue)
                            
                        }
                        _readerOk = xmlTextReaderRead(reader)
                        _currentNodeType = xmlTextReaderNodeType(reader)
                        
                    } else if("ReleaseOrg" == _currentElementName) {
                        
                        ReleaseOrgListArray.append(NGEOrgNameType(reader))
                        handledInChild = true
                        
                    } else   if(true) {
                        print("Ignoring unexpected in NGEReleaseHistoryType: \(_currentElementName)")
                        if superclass != NSObject.self {
                            break
                        }
                    }
                }
            }
            _readerOk = handledInChild ? xmlTextReaderReadState(reader) : xmlTextReaderRead(reader)
            _currentNodeType = xmlTextReaderNodeType(reader)
            _currentXmlDept = xmlTextReaderDepth(reader)
        }
        
        if(ReleaseOrgListArray.count > 0) { self.ReleaseOrgList = ReleaseOrgListArray }
    }
    
}

