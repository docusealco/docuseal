require 'rubyXL/objects/ooxml_object'
require 'rubyXL/objects/extensions'

module RubyXL
  # http://www.datypic.com/sc/ooxml/e-ssml_comment-1.html
  class Comment < OOXMLObject
    define_child_node(RubyXL::RichText, :node_name => 'text')
    define_child_node(RubyXL::AlternateContent)
    define_attribute(:ref,      :ref, :required => true)
    define_attribute(:authorId, :int, :required => true)
    define_attribute(:guid,     :string)
    define_element_name 'comment'
  end

  # http://www.datypic.com/sc/ooxml/e-ssml_authors-1.html
  class CommentList < OOXMLContainerObject
    define_child_node(RubyXL::Comment, :collection => [0..-1])
    define_element_name 'commentList'
  end

  # http://www.datypic.com/sc/ooxml/e-ssml_authors-1.html
  class Authors < OOXMLContainerObject
    define_child_node(RubyXL::StringNode, :node_name => :author, :collection => [0..-1])
    define_element_name 'authors'
  end

  # http://www.datypic.com/sc/ooxml/e-ssml_comments.html
  class CommentsFile < OOXMLTopLevelObject
    CONTENT_TYPE = 'application/vnd.openxmlformats-officedocument.spreadsheetml.comments+xml'
    REL_TYPE     = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/comments'.freeze

    define_child_node(RubyXL::Authors)
    define_child_node(RubyXL::CommentList)
    define_child_node(RubyXL::ExtensionStorageArea)
    define_element_name 'comments'
    set_namespaces('http://schemas.openxmlformats.org/spreadsheetml/2006/main' => nil)

    attr_accessor :workbook

    def xlsx_path
      ROOT.join('xl', "comments#{file_index}.xml")
    end
  end
end
