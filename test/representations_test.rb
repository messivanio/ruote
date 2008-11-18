
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Sun Apr 13 19:03:31 JST 2008
#

require 'rubygems'

require 'test/unit'

require 'openwfe/workitem'
require 'openwfe/flowexpressionid'
require 'openwfe/representations'
require 'openwfe/expool/representation'
require 'openwfe/engine/status_methods'

require 'rutest_utils'


class UtilXmlTest < Test::Unit::TestCase

  #def setup
  #end
  #def teardown
  #end

  Struct.new('RackRequest', :scheme, :host, :port)
  Struct.new('RailsRequest', :protocol, :host, :port)

  def test_0

    li = OpenWFE::LaunchItem.new
    li.attributes.delete "___map_type"
    xml = OpenWFE::Xml.launchitem_to_xml li

    assert_equal(
      "<?xml version=\"1.0\" encoding=\"UTF-8\"?><launchitem><workflow_definition_url></workflow_definition_url><attributes><hash></hash></attributes></launchitem>",
      xml)

    li = OpenWFE::Xml.launchitem_from_xml xml

    assert_nil(li.wfdurl)
    assert_equal({}, li.attributes)
  end

  def test_0b

    xml = %{<?xml version="1.0" encoding="UTF-8"?>
<process>
  <definition_url>http://processdef.server.example.com/process1</definition_url>
  <fields><hash></hash></fields>
</process>"}
    li = OpenWFE::Xml.launchitem_from_xml xml
    assert_equal('http://processdef.server.example.com/process1', li.wfdurl)
    assert_equal({}, li.attributes)
  end

  def test_0c

    xml = %{<?xml version="1.0" encoding="UTF-8"?>
<process>
  <definition>class ProcDef1 &lt; OpenWFE::ProcessDefinition
  sequence do
    participant "alpha"
    participant "bravo"
  end
end</definition>
  <fields><hash></hash></fields>
</process>"}

    li = OpenWFE::Xml.launchitem_from_xml xml

    assert_equal(nil, li.wfdurl)

    assert_equal(
      { '__definition' => %{class ProcDef1 < OpenWFE::ProcessDefinition
  sequence do
    participant "alpha"
    participant "bravo"
  end
end}}, li.attributes)
  end

  def test_1

    li = OpenWFE::LaunchItem.new
    li.attributes = { "a" => 1, "b" => 2, "c" => [ 1, 2, 3 ]}

    xml = OpenWFE::Xml.launchitem_to_xml li

    assert_equal(
      "<?xml version=\"1.0\" encoding=\"UTF-8\"?><launchitem><workflow_definition_url></workflow_definition_url><attributes><hash><entry><string>a</string><number>1</number></entry><entry><string>b</string><number>2</number></entry><entry><string>c</string><array><number>1</number><number>2</number><number>3</number></array></entry></hash></attributes></launchitem>",
      xml)

    li = OpenWFE::Xml.launchitem_from_xml xml

    assert_equal({ "a" => 1, "b" => 2, "c" => [ 1, 2, 3 ] }, li.attributes)
  end

  def test_2

    wi = OpenWFE::InFlowWorkItem.new
    wi.fei = new_fei

    xml = OpenWFE::Xml.workitem_to_xml wi

    wi1 = OpenWFE::Xml.workitem_from_xml xml

    assert_equal wi.fei, wi1.fei

    #p wi1.fei
  end

  def test_2b

    wi = OpenWFE::InFlowWorkItem.new
    wi.fei = new_fei

    wi1 = OpenWFE::InFlowWorkItem.from_xml(wi.to_xml)

    assert_equal wi.fei, wi1.fei

    #p wi1.fei
  end

  def test_2c

    wis = []

    2.times { |i|
      wi = OpenWFE::InFlowWorkItem.new
      wi.fei = new_fei
      #wi.uri = "/workitems/#{i}"
      wi.fei.expid = "0.#{i}"
      wis << wi
    }

    xml = OpenWFE::Xml.workitems_to_xml(wis, :indent => 2, :linkgen => :plain)

    #puts xml
    assert xml.match(/workitems/)
    assert xml.match(/link href="\/workitems\/20080919-equestris\/0_0"/)
    assert xml.match(/link href="\/workitems\/20080919-equestris\/0_1"/)

    workitems = OpenWFE::Xml.workitems_from_xml(xml)

    assert_equal 2, workitems.size
    assert_equal '/workitems/20080919-equestris/0_0', workitems.first.uri
    assert_equal '/workitems/20080919-equestris/0_1', workitems.last.uri
  end

  def test_3

    li = OpenWFE::LaunchItem.new
    li.wfdurl = 'http://toto'
    li.customer_name = 'toto'

    xml = OpenWFE::Xml.launchitem_to_xml li, :indent => 2

    li1 = OpenWFE::Xml.launchitem_from_xml xml

    assert_equal li.wfdurl, li1.wfdurl
    assert_equal li.customer_name, li1.customer_name
  end

  def test_pstatus_to_xml_and_json

    ps = new_process_status('20080919-equestribus')

    options = { :indent => 2, :linkgen => :plain }
    #puts OpenWFE::Xml.process_to_xml(ps, options)
    assert_match(
      /\/processes\/20080919-equestribus\//,
      OpenWFE::Xml.process_to_xml(ps, options))

    assert_equal(
      [
        { 'href' => '/processes', 'rel' => 'via' },
        { 'href' => '/processes/20080919-equestribus', 'rel' => 'self' },
        { 'href' => '/processes/20080919-equestribus/tree', 'rel' => 'related' }
      ],
      OpenWFE::Json.process_to_h(ps, :linkgen => :plain)['links'])
  end

  def test_pstatuses_to_xml_and_json

    rlr = Struct::RailsRequest.new('http://', 'www.example.com', 80)

    ps = [ '20080919-victrix', '20070909-gemina' ].inject({}) do |r, wfid|
      r[wfid] = new_process_status(wfid); r
    end

    options = { :indent => 2, :request => rlr, :linkgen => :plain }

    xml = OpenWFE::Xml.processes_to_xml(ps, options)
    #puts xml
    assert_match(/"\/processes"/, xml)
    assert_match(/count="2"/, xml)
    assert_match(/"\/processes\/20080919-victrix"/, xml)
    assert_match(/"\/processes\/20070909-gemina"/, xml)
  end

  protected

    def new_process_status (wfid)

      ps = OpenWFE::ProcessStatus.new
      class << ps
        attr_accessor :wfid
        def wfname; 'test-wf'; end
        def wfrevision; '0'; end
        def branches; 1; end
        def variables; { 'var0' => 'val0' }; end
        def scheduled_jobs; []; end
        def expressions; []; end
        def all_expressions
          return @a if @a
          @a = [ Object.new ]
          class << @a.first
            def fei; new_fei(wfid); end
            def raw_representation; [ 'test', {}, [] ]; end
            def children; []; end
          end
          class << @a
            def find_root_expression
              self.first
            end
          end
          @a.extend(OpenWFE::RepresentationMixin)
          @a
        end
      end
      ps.wfid = wfid

      ps
    end

end

