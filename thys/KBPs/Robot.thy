(*<*)
(*
 * Knowledge-based programs.
 * (C)opyright 2011, Peter Gammie, peteg42 at gmail.com.
 * License: BSD
 *)

theory Robot
imports
  ClockView
  SPRViewSingle
  "HOL-Library.Saturated"
begin

(*>*)
subsection{* The Robot *}

text{*
\label{sec:kbps-theory-robot}

\begin{figure}[tb]
 \includegraphics[width=\textwidth]{robot_clock}
 \caption{The implementation of the robot using the clock semantics.}
 \label{fig:kbps-theory-robot-clock}
\end{figure}

\begin{figure}[tb]
 \includegraphics[width=\textwidth]{robot_spr}
 \caption{The implementation of the robot using the SPR semantics.}
 \label{fig:kbps-theory-robot-spr}
\end{figure}

Recall the autonomous robot of \S\ref{sec:kbps-robot-intro}: we are
looking for an implementation of the KBP:
\begin{center}
  \begin{tabular}{lll}
    $\mathbf{do}$\\
     & $\gcalt$ $\mathbf{K}_{\mbox{robot}}$ \textsf{goal} & $\rightarrow$ \textsf{Halt}\\
     & $\gcalt$ $\lnot\mathbf{K}_{\mbox{robot}}$ \textsf{goal} & $\rightarrow$ \textsf{Nothing}\\
    $\mathbf{od}$\\
  \end{tabular}
\end{center}
in an environment where positions are identified with the natural
numbers, the robot's sensor is within one of the position, and the
proposition \textsf{goal} is true when the position is in
$\{2,3,4\}$. The robot is initially at position zero, and the effect
of its \textsf{Halt} action is to cause the robot to instantaneously
stop at its current position. A later \textsf{Nothing}
action may allow the environment to move the robot further to the
right.

To obtain a finite environment, we truncate the number line at 5,
which is intuitively sound for determinining the robot's behaviour due
to the synchronous view, and the fact that if it reaches this
rightmost position then it can never satisfy its objective.  Running
the Haskell code generated by Isabelle yields the automata shown in
Figure~\ref{fig:kbps-theory-robot-clock} and
Figure~\ref{fig:kbps-theory-robot-spr} for the clock and synchronous
perfect recall semantics respectively. These have been minimised using
Hopcroft's algorithm \citep{DBLP:journals/acta/Gries73}.

The (inessential) labels on the states are an upper bound on the set
of positions that the robot considers possible when it is in that
state. Transitions are annotated with the observations yielded by the
sensor. Double-circled states are those in which the robot performs
the \textsf{Halt} action, the others \textsf{Nothing}. We observe that
the synchronous perfect-recall view yields a ``ratchet'' protocol,
i.e. if the robot learns that it is in the goal region then it halts
for all time, and that it never overshoots the goal region. Conversely
the clock semantics allows the robot to infinitely alternate its
actions depending on the sensor reading. This is effectively the
behaviour of the intuitive implementation that halts iff the sensor
reads three or more.

We can also see that minimisation does not yield the smallest automata
we could hope for; in particular there are a lot of redundant states
where the prescribed behaviour is the same but the robot's state of
knowledge different. This is because our implementations do not
specify what happens on invalid observations, which we have modelled
as errors instead of don't-cares, and these extraneous distinctions
are preserved by bisimulation reduction. We discuss this further in
\S\ref{sec:kbps-alg-auto-min}.

*}(*<*)

(*

The environment protocol does nothing if the robot has signalled halt,
or chooses a new position and sensor reading if it hasn't.

We need a finite type to represent positions and observations. It is
sufficient to go to 5, for by then we are either halted in the goal
region or have gone past it.

*)

type_synonym digit = "5 sat"

datatype Agent = Robot
datatype EnvAct = Stay | MoveRight
datatype ObsError = Left | On | Right
datatype Proposition = Halted | InGoal
datatype RobotAct = NOP | Halt

type_synonym Halted = bool
type_synonym Pos = digit
type_synonym Obs = digit
type_synonym EnvState = "Pos \<times> Obs \<times> Halted"

definition
  envInit :: "EnvState list"
where
  "envInit \<equiv> [(0, 0, False), (0, 1, False)]"

definition
  envAction :: "EnvState \<Rightarrow> (EnvAct \<times> ObsError) list"
where
  "envAction \<equiv> \<lambda>_. [ (x, y) . x \<leftarrow> [Stay, MoveRight], y \<leftarrow> [Left, On, Right] ]"

definition
  newObs :: "digit \<Rightarrow> ObsError \<Rightarrow> digit"
where
  "newObs pos obserr \<equiv>
              case obserr of Left \<Rightarrow> pos - 1 | On \<Rightarrow> pos | Right \<Rightarrow> pos + 1"

definition
  envTrans :: "EnvAct \<times> ObsError \<Rightarrow> (Agent \<Rightarrow> RobotAct) \<Rightarrow> EnvState \<Rightarrow> EnvState"
where
  "envTrans \<equiv> \<lambda>(move, obserr) aact (pos, obs, halted).
    if halted
      then (pos, newObs pos obserr, halted)
      else
        case aact Robot of
           NOP \<Rightarrow> (case move of
                      Stay \<Rightarrow> (pos, newObs pos obserr, False)
                    | MoveRight \<Rightarrow> (pos + 1, newObs (pos + 1) obserr, False))
         | Halt \<Rightarrow> (pos, newObs pos obserr, True)"


definition
  envObs :: "EnvState \<Rightarrow> Obs"
where
  "envObs \<equiv> \<lambda>(pos, obs, halted). obs"

definition
  envVal :: "EnvState \<Rightarrow> Proposition \<Rightarrow> bool"
where
  "envVal \<equiv> \<lambda>(pos, obs, halted) p.
     case p of Halted \<Rightarrow> halted
             | InGoal \<Rightarrow> 2 \<le> pos \<and> pos \<le> (4 :: 5 sat)"

(* The KBP, clearly subjective. *)

definition
  kbp :: "(Agent, Proposition, RobotAct) KBP"
where
  "kbp \<equiv> [ \<lparr> guard = \<^bold>K\<^sub>Robot (Kprop InGoal),        action = Halt \<rparr>,
           \<lparr> guard = Knot (\<^bold>K\<^sub>Robot (Kprop InGoal)), action = NOP \<rparr> ]"

(*<*)

lemma Agent_univ: "(UNIV :: Agent set) = {Robot}"
  unfolding UNIV_def
  apply auto
  apply (case_tac x)
  apply auto
  done

instance Agent :: finite
  apply intro_classes
  apply (auto iff: Agent_univ)
  done

instantiation Agent :: linorder
begin

definition
  less_Agent_def: "(x::Agent) < y \<equiv> False"

definition
  less_eq_Agent_def: "(x::Agent) \<le> y \<equiv> x = y"

instance
  apply intro_classes
  unfolding less_Agent_def less_eq_Agent_def
  apply simp_all
  apply (case_tac x)
  apply (case_tac y)
  apply simp
  done
end

(*>*)

subsubsection{* Locale instantiations *}

interpretation Robot:
  Environment "\<lambda>_. kbp" envInit envAction envTrans envVal "\<lambda>_. envObs"
  apply unfold_locales
  apply (auto simp: kbp_def)
  apply ((case_tac a, simp)+)
  done

subsubsection{* The Clock view implementation *}

interpretation Robot_Clock:
  FiniteLinorderEnvironment "\<lambda>_. kbp" envInit envAction envTrans envVal "\<lambda>_. envObs" "fromList [Robot]"
  apply unfold_locales
  apply (simp add: Agent_univ)
  done

abbreviation "Agents \<equiv> ODList.fromList [Robot]"

definition
  robot_ClockDFS :: "((EnvState, RobotAct list) clock_acts_trie, (EnvState, digit) clock_trans_trie) AlgState"
where
  "robot_ClockDFS \<equiv> ClockAutoDFS Agents (\<lambda>_. kbp) envInit envAction envTrans envVal (\<lambda>_. envObs) Robot"

definition
  robot_ClockAlg :: "Agent \<Rightarrow> (digit, RobotAct, EnvState odlist \<times> EnvState odlist) Protocol"
where
  "robot_ClockAlg \<equiv> mkClockAuto Agents (\<lambda>_. kbp) envInit envAction envTrans envVal (\<lambda>_. envObs)"

lemma (in FiniteLinorderEnvironment)
  "Robot.Clock.implements robot_ClockAlg"
  unfolding robot_ClockAlg_def by (rule Robot_Clock.mkClockAuto_implements)

subsubsection{* The SPR view implementation *}

interpretation Robot_SPR:
  FiniteSingleAgentEnvironment "\<lambda>_. kbp" envInit envAction envTrans envVal "\<lambda>_. envObs" "Robot"
  apply unfold_locales
  apply (case_tac a, simp)
  done

definition
  robot_SPRSingleDFS :: "(RobotAct, digit, EnvState) SPRSingleAutoDFS"
where
  "robot_SPRSingleDFS \<equiv> SPRSingleAutoDFS kbp envInit envAction envTrans envVal (\<lambda>_. envObs) Robot"

definition
  robot_SPRSingleAlg :: "Agent \<Rightarrow> (digit, RobotAct, EnvState odlist) Protocol"
where
  "robot_SPRSingleAlg \<equiv> mkSPRSingleAuto kbp envInit envAction envTrans envVal (\<lambda>_. envObs)"

lemma (in FiniteSingleAgentEnvironment)
  "Robot.Robot.SPR.implements robot_SPRSingleAlg"
  unfolding robot_SPRSingleAlg_def by (rule Robot.Robot_SPR.mkSPRSingleAuto_implements)

end
(*>*)
