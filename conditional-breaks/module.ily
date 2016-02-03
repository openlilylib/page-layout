%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
% This file is part of openLilyLib,                                           %
%                      ===========                                            %
% the community library project for GNU LilyPond                              %
% (https://github.com/openlilylib)                                            %
%              -----------                                                    %
%                                                                             %
% Package: page-layout                                                        %
%          ===========                                                        %
%                                                                             %
% openLilyLib is free software: you can redistribute it and/or modify         %
% it under the terms of the GNU General Public License as published by        %
% the Free Software Foundation, either version 3 of the License, or           %
% (at your option) any later version.                                         %
%                                                                             %
% openLilyLib is distributed in the hope that it will be useful,              %
% but WITHOUT ANY WARRANTY; without even the implied warranty of              %
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the               %
% GNU General Public License for more details.                                %
%                                                                             %
% You should have received a copy of the GNU General Public License           %
% along with openLilyLib. If not, see <http://www.gnu.org/licenses/>.         %
%                                                                             %
% openLilyLib is maintained by Urs Liska, ul@openlilylib.org                  %
% and others.                                                                 %
%       Copyright Urs Liska, 2016                                             %
%                                                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



% This functionality relies on the edition-engraver
% which is temporarily included from the openlilylib/snippets repository
% (which has to be in LilyPond's include path)
\include "editorial-tools/edition-engraver/definitions.ily"
\addEdition conditional-breaks

% Configure which breaks to use.
% The option expects a symbol-list containing any combination of
% - 'line-breaks
% - 'page-breaks
% - 'page-turns
% Each element that is present will be respected.
% By default line-breaks are used, page breaks and page turns ignored
% For their interaction please refer to the comments to and in
% \applyConditionalBreaks.
\registerOption page-layout.conditional-breaks.use #'(line-breaks)

% Calling of this function is necessary to actually process the conditional breaks.
% Place it after all break lists have been set.
% - set: the named set as a Scheme symbol, e.g. \applyConditionalBreaks #'original-edition
applyConditionalBreaks =
#(define-void-function (set) (symbol?)
   (let* (
           ;; configure which types of breaks are kept.
           ;; If page breaks or page turns are disabled they are not inserted.
           ;; However, if line breaks are enabled, page breaks and page turns
           ;; are inserted as line breaks.
           ;; Any combination should produce the expected results.
           (base-path '(page-layout conditional-breaks use))
           (breaks-to-use (getOption base-path))
           (keep-conditional-line-breaks (member 'line-breaks breaks-to-use))
           (keep-conditional-page-breaks (member 'page-breaks breaks-to-use))
           (keep-conditional-page-turns (member 'page-turns breaks-to-use))

           ;; Load a set of break positions.
           (break-set `(breaks break-sets ,set))
           (conditionalLineBreaks (getChildOption break-set 'line-breaks))
           (conditionalPageBreaks (getChildOption break-set 'page-breaks))
           (conditionalPageTurns (getChildOption break-set 'page-turns))

           ;; process possible combinations of options
           (lbreaks (if keep-conditional-line-breaks
                        ;; if line breaks are used we compose a list from
                        ;; the original line breaks and the page breaks/turns
                        ;; if these aren't kept separately
                        (append
                         conditionalLineBreaks
                         (if (not keep-conditional-page-breaks)
                             conditionalPageBreaks
                             '())
                         (if (not keep-conditional-page-turns)
                             conditionalPageTurns
                             '()))
                        ;; if line breaks are discarded they are so completely
                        '()))
           (lpbreaks (if keep-conditional-page-breaks
                         conditionalPageBreaks
                         '()))
           (lpturns (if keep-conditional-page-turns
                        conditionalPageTurns
                        '()))
           (linebreaks (if keep-conditional-line-breaks
                           (append lbreaks lpbreaks lpturns)
                           lbreaks))

           ;; if we do not respect page breaks we use an empty list
           (pagebreaks (if keep-conditional-page-breaks
                           lpbreaks
                           '()))
           ;; if we do not respect page turns we use an empty list
           (pageturns (if keep-conditional-page-turns
                          lpturns
                          '())))

     ;; apply the determined breaks as edition-engraver commands
     #{
       \editionModList conditional-breaks conditional-breaks.Score.A
       \break #linebreaks
       \editionModList conditional-breaks conditional-breaks.Score.A
       \pageBreak #pagebreaks
       \editionModList conditional-breaks conditional-breaks.Score.A
       \pageTurn #pageturns
     #}))

% "Install" the edition-engraver in the score
\layout {
  \context {
    \Score
    \consists \editionEngraver conditional-breaks
  }
}
