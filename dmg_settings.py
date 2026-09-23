import os

# Volume Name
volume_name = 'MyScreen'

# Format & Filesystem
format = 'UDZO'
filesystem = 'HFS+'

# Background Image (HiDPI TIFF)
background = 'Sources/MyScreen/Resources/dmg_background.tiff'

# Window layout: ((x, y), (w, h))
window_rect = ((200, 120), (632, 424))

# Icon view settings
default_view = 'icon-view'
icon_size = 90.0
text_size = 12.0
show_status_bar = False
show_tab_view = False
show_toolbar = False
show_pathbar = False
show_sidebar = False

# Files to include (Clean names without visible labels)
NBSP_1 = '\u00A0'
NBSP_2 = '\u00A0\u00A0'

files = [
    ('build/Install MyScreen.app', f'{NBSP_1}.app')
]

symlinks = {
    NBSP_2: '/Applications'
}

icon_locations = {
    f'{NBSP_1}.app': (180, 212),
    NBSP_2: (452, 212)
}

hide_extensions = [f'{NBSP_1}.app']

# Volume icon
badge_icon = 'Sources/MyScreen/Resources/AppIcon.icns'
