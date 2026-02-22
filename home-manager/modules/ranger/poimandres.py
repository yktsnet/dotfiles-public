from ranger.gui.colorscheme import ColorScheme
from ranger.gui.color import *


class Poimandres(ColorScheme):
    def use(self, context):
        fg, bg, attr = default_colors

        if context.reset:
            return default_colors

        if context.directory:
            attr = bold
            if context.permissions & 0o002:
                fg = 2
            else:
                fg = 4

        elif context.link:
            if not context.good:
                fg = 1
                bg = 0
                attr = reverse | bold
            else:
                fg = 7
                attr = normal

        elif context.socket or context.fifo:
            fg = 5
            attr = bold

        elif context.executable and not any((context.media, context.container)):
            fg = 2
            attr = bold

        elif context.file:
            fg = 7
            attr = normal

        if context.selected:
            if context.main_column:
                fg = 0
                bg = 4
                attr |= bold
            else:
                attr |= reverse

        return fg, bg, attr
