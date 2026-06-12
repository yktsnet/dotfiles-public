-- Remove file size (2) from the left
Status:children_remove(2, Status.LEFT)

-- Remove permissions (4), scroll percentage (5), and position (6) from the right
Status:children_remove(4, Status.RIGHT)
Status:children_remove(5, Status.RIGHT)
Status:children_remove(6, Status.RIGHT)

-- Load and setup git-branch plugin
require("git-branch"):setup()
