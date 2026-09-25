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

# Files to include (Standard native MyScreen app)
files = [
    'build/MyScreen.app'
]

# Applications symlink
symlinks = {
    'Applications': '/Applications'
}

# Icon locations centered on glass pedestals
icon_locations = {
    'MyScreen.app': (180, 212),
    'Applications': (452, 212)
}

# Hide .app extension so Finder displays clean "MyScreen" label
hide_extensions = ['MyScreen.app']

# Volume icon
badge_icon = 'Sources/MyScreen/Resources/AppIcon.icns'
