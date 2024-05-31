;sect header
#
# IAC 2023/2024 k-means
# 
# Grupo: 1
# Campus: Taguspark
#
# Autores:
# 106196, Diogo Cruz Diniz
#
# Tecnico/ULisboa

# INTRO:
# There are a lot of comment lines in this style at the header that explain several things in the project
# They can be moslty ignored but they also justify a lot of the decisions made in the code. 

# PREPROCESSING:
# The provided code was processed by RV_Fabrication v1.0 by Didas72 with command 'RV_Fabrication -lS src/main.s'
# The preprocessor performs includes with section preservation, auto-saving of registers, function calls and inlines (latter unused), symbol poisoning and macro application (unused)
# Code can be provided as needed. (kept in a private repository until final project submission)
# The output code was cleaned by hand to strip some of the generated comments that cluttered the code.
# These mostly consisted of commented function code, which is replaced by processed code.
# Preprocessor directives were preserved. These are mostly unintrusive and help understand how the preprocessor was used.

# RIPES:
# The LED matrix is expected to be 32 by 32.

# C COMMENTS:
# In all C translation comments, pointers are assumed to be char* or equivalent.
# Pointer scaling is done by hand and ignored in the comments

# FUNCTION DOCUMENTATION:
# Functions are documented as follows:
#
# ;funcdecl <name> <argc> [inlinehint]
# # <name>(<arguments>*); //<remarks>
# [further notes]
# <name>:
# # <register usage>
#
# Where
# <argument> can be either:
#    '[modifier] <type> [name]' - for most arguments
#    '<reg>=<argument>' - for shortening function declarations
#    '<modifier>'
# modifiers can be 'return' for arguments which are also return values, 'destroy' for regs which are overwritten or 'const' if the register is not altered
# NOTE: The argument notes are mere hints, not to be used as specs. The RV calling convention is the spec.
# NOTE: The behaviours of functions explicitly requested are less documented since theire behaviour was not defined by me.

# LABELS:
# A lot of labels throughout the code are never referenced.
# These are present for readability. All labels follow a specific format:
# <function_name>: - for regular function declaration
# _<function_name>_<internal_name>: - for 'function-private' labels
# Label placement is also part of the documentation
# When a label is preceeded by a blank line, it denotes a separate block of code,
# whereas a label that is preceeded by a line of code, is either used in a jump or is a mere name for part of the 'code sequence'.

# DEBUGGING FUNCTIONS:
# Several functions were implemented for debugging purposes. These were preserved for future reference but their calls removed with an exception.
# The debugging functions fall into two groups: log and sleep.
# Functions used for logging are defined in dbg.s and are simple prints to the RIPES console.
# The only sleep function if defines in sleep.s and it actively waits X milliseconds. Calls to this function were preserved as they help see the algorithm in action.

# EXTRA VARIABLES:
# Only 'centroids_prev' was added as an extra variable. It holds the previous state of 'centroids'.
# It is used to detect changes in the centroids, to determine when to stop the algorithm.

# SAVED REGISTERS AND OPTIMIZATIONS:
# Certain functions use more sX registers than may seem necessary.
# These are mostly array base pointers that could be 'la'd as needed, but they were kept in dedicated
# registers to speed up pointer calculation, given the lack of indexing options in RISC-V I.
# This results in more push/pop operations but the perfomance gain was considered worth the trouble.
# This optimization was not always used.
#
# In 'leaf' functions, tX registers were used to avoid unnecessary pushs of sX registers.
# This goes against the RISC-V convention, but register integrity was ensured by the preprocessor.

# CONCLUSIONS/RESTROSPECTIVE:
# An optimization to array traversal was noticed halfway through the project and was not applied everywhere.
# When traversing arrays backwards, there is no need to keep a 'limit' register, used widely across the code.
# The simple comparison between the index and zero suffices to determine the stop condition, sparing a register per array traversed.
#
# There could have been more consistency with what optimizations where and were not used, which might have made the code less readable.
