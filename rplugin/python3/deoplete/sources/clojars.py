from .base import Base
import netrc
import re
import base64

class Source(Base):

    def __init__(self, vim):
        Base.__init__(self, vim)

        self.name = 'clojars'
        self.mark = '[clojars]'
        self.filetypes = ['clj', 'clojure']

    def gather_candidates(self, context):

        complete_str = context['complete_str']
        line = self.vim.call('getline', '.')
        col = self.vim.call('col', '.')-1
        to_cursor = line[:col]

        if '[' not in to_cursor:
            return []

        titles = [{'word': x,
                   'menu': x,
                   'info': x}
                   for x in self.vim.call('cljreloaded#AllAvailableJars', complete_str)]
        return titles
