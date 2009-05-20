#--
# Copyright (c) 2005-2009, John Mettraux, jmettraux@gmail.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Made in Japan.
#++

require 'ruote/exp/flowexpression'


module Ruote

  # An expression for echoing text to STDOUT or to a :s_tracer service
  # (if there is one bound in the engine context).
  #
  #   sequence do
  #     participant :ref => 'toto'
  #     echo 'toto replied'
  #   end
  #
  class EchoExpression < FlowExpression

    names :echo

    def apply (workitem)

      reply(workitem)
    end

    def reply (workitem)

      #text = "#{workitem.attributes['__result__'].to_s}\n"
      #text = "#{raw_children.first.to_s}\n"
      text = "#{attribute_text(workitem)}\n"

      if t = context[:s_tracer]
        t << text
      else
        print(text)
      end

      reply_to_parent(workitem)
    end
  end
end

