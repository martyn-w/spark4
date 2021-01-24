class PeopleController < ApplicationController

  def index
    filename = File.join(Settings.output,'person', 'index.xml')

    if File.exists?(filename)
      render body: transform(person_index_xslt, filename), status: :ok, content_type: 'text/html'
    else
      render plain: "Index file not found: #{filename}", status: :not_found
    end
  end

  def show
    filename = File.join(Settings.output,'person', "#{params[:id]}.xml")

    if File.exists?(filename)
      render body: transform(person_xslt, filename), status: :ok, content_type: 'text/html'
    else
      render plain: "Not found: #{params[:id]}", status: :not_found
    end
  end

private

  def transform(stylesheet, filename)
    doc = Nokogiri::XML(File.open(filename))
    stylesheet.transform(doc)
  end

  def person_xslt
    @person_xslt = Nokogiri::XSLT(File.open(File.join(Settings.output,'xsl','person.xsl')))
  end

  def person_index_xslt
    @person_index_xslt = Nokogiri::XSLT(File.open(File.join(Settings.output,'xsl','person-index.xsl')))
  end
end
