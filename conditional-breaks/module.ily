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

\addEdition conditional-breaks

% Configure which breaks to use.
% The option expects either a symbol-list containing any combination of
% - 'line-breaks
% - 'page-breaks
% - 'page-turns
% or a single symbol or string with either entry or "all"
% Each element that is present will be respected.
% By default all breaks are used
% For their interaction of the options please refer to the comments to
% and in \applyConditionalBreaks.
\registerOption page-layout.conditional-breaks.use all

% By default \applyConditionalBreaks prohibits automatic breaks.
% In order to allow them (for example to use the functionality to
% simply force *some* breaks) set this option to ##t
\registerOption page-layout.conditional-breaks.allow-auto ##f

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
           (breaks-to-use
            ;; This rather complicated assignment is necessary to
            ;; - allow symbol-list or symbol or string as the option value
            ;; - allow the use of 'all as option
            (let* ((use (getOption '(page-layout conditional-breaks use)))
                   ;; ensure a symbol-list
                   (use-list (if (list? use)
                                 use
                                 (list
                                  (if (string? use)
                                      (string->symbol use)
                                      use)))))
              (if (member 'all use-list)
                  '(line-breaks page-breaks page-turns)
                  use-list)))

           ;; Load a set of break positions.
           (break-set `(breaks break-sets ,set))
           (conditionalLineBreaks (getChildOption break-set 'line-breaks))
           (conditionalPageBreaks (getChildOption break-set 'page-breaks))
           (conditionalPageTurns (getChildOption break-set 'page-turns))

           ;; Which break types to be kept?
           (keep-line-breaks (member 'line-breaks breaks-to-use))
           (keep-page-breaks (member 'page-breaks breaks-to-use))
           (keep-page-turns (member 'page-turns breaks-to-use))

           ;; process possible combinations of options

           ;; page breaks and page turns are only used when set through option
           (pagebreaks (if keep-page-breaks
                         conditionalPageBreaks
                         '()))
           (pageturns (if keep-page-turns
                        conditionalPageTurns
                        '()))
           ;; if line breaks are not used *no* line breaks are issued at all.
           ;; if line breaks are used then unused page breaks or page turns
           ;; are converted to line breaks (if I don't set the use of page breaks
           ;; I still want to render them as line breaks)
           (linebreaks (if keep-line-breaks
                           (append conditionalLineBreaks
                             (if keep-page-breaks '() conditionalPageBreaks)
                             (if keep-page-turns '() conditionalPageTurns))
                           '()))
           ;; retrieve all line breaks that are not at barlines
           (in-measure-breaks
            (filter pair? (append linebreaks pagebreaks pageturns))))

     ;; apply the determined breaks as edition-engraver commands
     #{
       % Prevent automatic breaks between the explicitly defined ones.
       \editionMod conditional-breaks 1 0/4 breaks.Score.A
       \override Score.NonMusicalPaperColumn.line-break-permission =
       \getOption page-layout.conditional-breaks.allow-auto
       % insert invisible barlines to enable breaks within measures
       \editionModList conditional-breaks breaks.Score.A
       \bar "" #in-measure-breaks
       \editionModList conditional-breaks breaks.Score.A
       \break #linebreaks
       \editionModList conditional-breaks breaks.Score.A
       \pageBreak #pagebreaks
       \editionModList conditional-breaks breaks.Score.A
       \pageTurn #pageturns
     #}))
