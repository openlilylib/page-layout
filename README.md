# page-layout

This [openLilyLib](https://openlilylib.org) package provides functionality to work with page
layout in the [Lilypond](http://lilypond.org) notation program.

## Conditional Breaks

The `conditional-breaks` module allows the application of alternative sets of line/page breaks,
e.g. to reflect different musical sources or to match the layout of the engraver's copy while
entering the music.  This works unintrusively as the breaks are not mixed with the content in
any way.

```lilypond
\version "2.19.36"

% Load the package, this will be redone using lyp
% Implicitly loads oll-core
\include "page-layout/package.ly"
\loadModule page-layout conditional-breaks

% Register two alternative break sets.
\registerBreakSet original-edition
\setBreaks original-edition line-breaks #'(3 (4 2/4) 5 13)
\setBreaks original-edition page-breaks #'(8)
\setBreaks original-edition page-turns #'(15)

\registerBreakSet manuscript
\setBreaks manuscript  line-breaks #'(5 10 17 24)
\setBreaks manuscript  page-breaks #'(13)

% Configure which breaks to respect
\setOption page-layout.conditional-breaks.use #'(line-breaks page-breaks)

% Apply a break set. (Applying multiple sets will use *all*)
\applyConditionalBreaks original-edition
%\applyConditionalBreaks manuscript

{
  \repeat unfold 40 c''2
}
```