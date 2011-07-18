# -*- coding: utf-8 -*-
require 'net/http'
require 'rexml/document'

class DicSession
  @@address = 'btonic.est.co.jp'
  @@searchPath = '/NetDic/NetDicV09.asmx/SearchDicItemLite?&Dic=EJdict&Word='
  @@searchOptions = '&Scope=HEADWORD&Match=EXACT&Merge=OR&Prof=XHTML&PageSize=10&PageIndex=0'
  @@retrievePath = '/NetDic/NetDicV09.asmx/GetDicItemLite?Dic=EJdict&Item='
  def initialize()
    @session = Net::HTTP.start(@@address)
  end
  def searchDic(word)
    response = @session.get(@@searchPath + word + @@searchOptions)
    xml = REXML::Document.new response.body
    if REXML::XPath.first(xml, '//ItemCount').text.to_i == 0
      return nil
    end
    return xml
  end
  def retrieveDic(itemId)
    response = @session.get(@@retrievePath + itemId + '&Loc=&Prof=XHTML')
    xml = REXML::Document.new response.body
    result = REXML::XPath.first(xml, '//span[@class="NetDicHeadTitle"]').text + '\n' +
      REXML::XPath.first(xml, '//div[@class="NetDicBody"]/div').text + '\n'
    return result
  end
end
