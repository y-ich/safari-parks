# -*- coding: utf-8 -*-
#
# イースト辞書WebサービスAPI
# 未使用
require 'net/http'
require 'rexml/document'

class DicSession
  ADDRESS = 'btonic.est.co.jp'
  SEARCH_PATH = '/NetDic/NetDicV09.asmx/SearchDicItemLite'
  RETRIEVE_PATH = '/NetDic/NetDicV09.asmx/GetDicItemLite'

  def initialize()
    @session = Net::HTTP.start(ADDRESS)
  end

  def close
    @session.finish
  end

# 単語に該当するitemIdの配列を返します。
  def search(word, match)
    params = {
      :Dic => 'EJdict', # 'EJdict', 'EdictJE', 'wpedia'
      :Word => word,
      :Scope => 'HEADWORD', # 'HEADWORD', 'ANYWHERE'
      :Match => match, # 'STARTWITH', 'ENDWITH', 'CONTAIN', 'EXACT'
      :Merge => 'OR', # 'AND', 'OR'
      :Prof => 'XHTML',
      :PageSize => '10',
      :PageIndex => '0'
    }
    response = @session.get(SEARCH_PATH + '?' + params_to_string(params))
    xml = REXML::Document.new response.body

    result = []
    REXML::XPath.each(xml, '//ItemID') { |e| result.push(e.text) }
    return result
  end

# itemId(数値文字列)に対応する単語の意味を取り出します。
  def retrieve(itemId)
    params = {
      :Dic => 'EJdict',
      :Item => itemId,
      :Loc => '',
      :Prof => 'XHTML'
    }
    response = @session.get(RETRIEVE_PATH + '?' + params_to_string(params))
    xml = REXML::Document.new response.body
    result = REXML::XPath.first(xml, '//span[@class="NetDicHeadTitle"]').text +
      '\n' +
      REXML::XPath.first(xml, '//div[@class="NetDicBody"]/div').text + '\n'
    return result
  end

  private
  
  def params_to_string(params)
    params.collect {|k, e| k.to_s + '=' + e }.join('&')
  end
end
