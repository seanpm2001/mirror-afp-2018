(*******************************************************************************

  Project: Refining Authenticated Key Agreement with Strong Adversaries

  Module:  dhlvl1.thy (Isabelle/HOL 2016-1)
  ID:      $Id: dhlvl1.thy 133183 2017-01-31 13:55:43Z csprenge $
  Author:  Joseph Lallemand, INRIA Nancy <joseph.lallemand@loria.fr>
           Christoph Sprenger, ETH Zurich <sprenger@inf.ethz.ch>
  
  Level-1 Diffie-Hellman guard protocol.

  Copyright (c) 2015-2016 Joseph Lallemand and Christoph Sprenger
  Licence: LGPL

*******************************************************************************)

section \<open>Authenticated Diffie Hellman Protocol (L1)\<close>

theory dhlvl1
imports Runs Secrecy AuthenticationI Payloads
begin

declare option.split_asm [split]

(**************************************************************************************************)
subsection \<open>State and Events\<close>
(**************************************************************************************************)

consts
  Nend :: "nat"

abbreviation nx :: nat where "nx \<equiv> 2"
abbreviation ny :: nat where "ny \<equiv> 3"

text \<open>Proofs break if @{term "1"} is used, because @{method "simp"} replaces it with
@{term "Suc 0"}\dots.\<close>
abbreviation
  "xEnd \<equiv> Var 0"

abbreviation
  "xnx \<equiv> Var 2"

abbreviation
  "xny \<equiv> Var 3"

abbreviation
  "xsk \<equiv> Var 4"

abbreviation
  "xgnx \<equiv> Var 5"

abbreviation
  "xgny \<equiv> Var 6"



abbreviation 
  "End \<equiv> Number Nend"


text \<open>Domain of each role (protocol dependent).\<close>

fun domain :: "role_t \<Rightarrow> var set" where
  "domain Init = {xnx, xgnx, xgny, xsk, xEnd}"
| "domain Resp = {xny, xgnx, xgny, xsk, xEnd}"


consts
  test :: rid_t
  
consts
  guessed_runs :: "rid_t \<Rightarrow> run_t"
  guessed_frame :: "rid_t \<Rightarrow> frame"

text \<open>Specification of the guessed frame: 
\begin{enumerate}
\item Domain
\item Well-typedness.
  The messages in the frame of a run never contain implementation material
  even if the agents of the run are dishonest.
  Therefore we consider only well-typed frames.
  This is notably required for the session key compromise; it also helps proving
  the partitionning of ik,
  since we know that the messages added by the protocol do not contain ltkeys in their
  payload and are therefore valid implementations.
\item We also ensure that the values generated by the frame owner are correctly guessed.
\end{enumerate}\<close>
specification (guessed_frame) 
  guessed_frame_dom_spec [simp]:
    "dom (guessed_frame R) = domain (role (guessed_runs R))"
  guessed_frame_payload_spec [simp, elim]:
    "guessed_frame R x = Some y \<Longrightarrow> y \<in> payload"
  guessed_frame_Init_xnx [simp]: 
    "role (guessed_runs R) = Init \<Longrightarrow> guessed_frame R xnx = Some (NonceF (R$nx))"
  guessed_frame_Init_xgnx [simp]: 
    "role (guessed_runs R) = Init \<Longrightarrow> guessed_frame R xgnx = Some (Exp Gen (NonceF (R$nx)))"
  guessed_frame_Resp_xny [simp]: 
    "role (guessed_runs R) = Resp \<Longrightarrow> guessed_frame R xny = Some (NonceF (R$ny))"
  guessed_frame_Resp_xgny [simp]: 
    "role (guessed_runs R) = Resp \<Longrightarrow> guessed_frame R xgny = Some (Exp Gen (NonceF (R$ny)))"
  guessed_frame_xEnd [simp]:
    "guessed_frame R xEnd = Some End"
apply (rule exI [of _ 
    "\<lambda>R.
      if role (guessed_runs R) = Init then
        [xnx \<mapsto> NonceF (R$nx), xgnx \<mapsto> Exp Gen (NonceF (R$nx)), xgny \<mapsto> End, 
         xsk \<mapsto> End, xEnd \<mapsto> End]
      else
        [xny \<mapsto> NonceF (R$ny), xgnx \<mapsto> End, xgny \<mapsto> Exp Gen (NonceF (R$ny)), 
         xsk \<mapsto> End, xEnd \<mapsto> End]"],
  auto simp add: domIff intro: role_t.exhaust) 
done

abbreviation
  "test_owner \<equiv> owner (guessed_runs test)"

abbreviation
  "test_partner \<equiv> partner (guessed_runs test)"


text \<open>Level 1 state.\<close>

record l1_state = 
  s0_state +
  progress :: progress_t
  signalsInit :: "signal \<Rightarrow> nat"
  signalsResp :: "signal \<Rightarrow> nat"


type_synonym l1_obs = "l1_state"


abbreviation
  run_ended :: "var set option \<Rightarrow> bool"
where
  "run_ended r \<equiv> in_progress r xEnd"

lemma run_ended_not_None [elim]:
  "run_ended R \<Longrightarrow> R = None \<Longrightarrow> False"
by (fast dest: in_progress_Some)

text \<open>@{term "test_ended s"} $\longleftrightarrow$ the test run has ended in @{term "s"}.\<close>

abbreviation
  test_ended :: "'a l1_state_scheme \<Rightarrow> bool"
where
  "test_ended s \<equiv> run_ended (progress s test)"

text \<open>A run can emit signals if it involves the same agents as the test run, and if the test run 
  has not ended yet.\<close>

definition
  can_signal :: "'a l1_state_scheme \<Rightarrow> agent \<Rightarrow> agent \<Rightarrow> bool"
where
  "can_signal s A B \<equiv>
  ((A = test_owner \<and> B = test_partner) \<or> (B = test_owner \<and> A = test_partner)) \<and>
  \<not> test_ended s"


text \<open>Events.\<close>

definition
  l1_learn :: "msg \<Rightarrow> ('a l1_state_scheme * 'a l1_state_scheme) set"
where
  "l1_learn m \<equiv> {(s,s').
    \<comment> \<open>guard\<close>
    synth (analz (insert m (ik s))) \<inter> (secret s) = {}  \<and>
    \<comment> \<open>action\<close>
    s' = s \<lparr>ik := ik s \<union> {m}\<rparr>
  }"


text \<open>Potocol events.\<close>

text \<open>
\begin{itemize}
\item step 1: create @{term "Ra"}, @{term "A"} generates @{term "nx"},
  computes $@{term "g"}^@{term "nx"}$
\item step 2: create @{term "Rb"}, @{term "B"} reads $@{term "g"}^@{term "nx"}$ insecurely,
  generates @{term "ny"}, computes $@{term "g"}^@{term "ny"}$,
  computes $@{term "g"}^@{term "nx*ny"}$,
  emits a running signal for @{term "Init"}, $@{term "g"}^@{term "nx*ny"}$
\item step 3: @{term "A"} reads $@{term "g"}^@{term "ny"}$ and $@{term "g"}^@{term "nx"}$
  authentically,
  computes $@{term "g"}^@{term "ny*nx"}$, emits a commit signal for @{term "Init"},
  $@{term "g"}^@{term "ny*nx"}$, a running signal for @{term "Resp"}, $@{term "g"}^@{term "ny*nx"}$,
  declares the secret $@{term "g"}^@{term "ny*nx"}$
\item step 4: @{term "B"} reads $@{term "g"}^@{term "nx"}$ and $@{term "g"}^@{term "ny"}$
  authentically,
  emits a commit signal for @{term "Resp"}, $@{term "g"}^@{term "nx*ny"}$,
  declares the secret $@{term "g"}^@{term "nx*ny"}$
\end{itemize}
\<close>

definition
  l1_step1 :: "rid_t \<Rightarrow> agent \<Rightarrow> agent \<Rightarrow> ('a l1_state_scheme * 'a l1_state_scheme) set"
where
  "l1_step1 Ra A B \<equiv> {(s, s').
    \<comment> \<open>guards:\<close>
    Ra \<notin> dom (progress s) \<and>
    guessed_runs Ra = \<lparr>role=Init, owner=A, partner=B\<rparr> \<and>
    \<comment> \<open>actions:\<close>
    s' = s\<lparr>
      progress := (progress s)(Ra \<mapsto> {xnx, xgnx})
      \<rparr>
  }"


definition
  l1_step2 :: "rid_t \<Rightarrow> agent \<Rightarrow> agent \<Rightarrow> msg \<Rightarrow> ('a l1_state_scheme * 'a l1_state_scheme) set"
where
  "l1_step2 Rb A B gnx \<equiv> {(s, s').
    \<comment> \<open>guards:\<close>
    guessed_runs Rb = \<lparr>role=Resp, owner=B, partner=A\<rparr> \<and>
    Rb \<notin> dom (progress s) \<and>
    guessed_frame Rb xgnx = Some gnx \<and>
    guessed_frame Rb xsk = Some (Exp gnx (NonceF (Rb$ny))) \<and>
    \<comment> \<open>actions:\<close>
    s' = s\<lparr> progress := (progress s)(Rb \<mapsto> {xny, xgny, xgnx, xsk}),
            signalsInit := if can_signal s A B then
                          addSignal (signalsInit s) (Running A B (Exp gnx (NonceF (Rb$ny))))
                       else
                          signalsInit s
          \<rparr>
  }"

definition
  l1_step3 :: "rid_t \<Rightarrow> agent \<Rightarrow> agent \<Rightarrow> msg \<Rightarrow> ('a l1_state_scheme * 'a l1_state_scheme) set"
where
  "l1_step3 Ra A B gny \<equiv> {(s, s').
    \<comment> \<open>guards:\<close>
    guessed_runs Ra = \<lparr>role=Init, owner=A, partner=B\<rparr> \<and>
    progress s Ra = Some {xnx, xgnx} \<and>
    guessed_frame Ra xgny = Some gny \<and>
    guessed_frame Ra xsk = Some (Exp gny (NonceF (Ra$nx))) \<and>
    (can_signal s A B \<longrightarrow> \<comment> \<open>authentication guard\<close>
      (\<exists> Rb. guessed_runs Rb = \<lparr>role=Resp, owner=B, partner=A\<rparr> \<and>
             in_progressS (progress s Rb) {xny, xgnx, xgny, xsk} \<and>
             guessed_frame Rb xgny = Some gny \<and>
             guessed_frame Rb xgnx = Some (Exp Gen (NonceF (Ra$nx))))) \<and>
    (Ra = test \<longrightarrow> Exp gny (NonceF (Ra$nx)) \<notin> synth (analz (ik s))) \<and>

    \<comment> \<open>actions:\<close>
    s' = s\<lparr> progress := (progress s)(Ra \<mapsto> {xnx, xgnx, xgny, xsk, xEnd}),
            secret := {x. x = Exp gny (NonceF (Ra$nx)) \<and> Ra = test} \<union> secret s,
            signalsInit := if can_signal s A B then
                         addSignal (signalsInit s) (Commit A B (Exp gny (NonceF (Ra$nx))))
                       else
                         signalsInit s,
            signalsResp := if can_signal s A B then
                         addSignal (signalsResp s) (Running A B (Exp gny (NonceF (Ra$nx))))
                       else
                         signalsResp s

          \<rparr>
  }"


definition
  l1_step4 :: "rid_t \<Rightarrow> agent \<Rightarrow> agent \<Rightarrow> msg \<Rightarrow> ('a l1_state_scheme * 'a l1_state_scheme) set"
where
  "l1_step4 Rb A B gnx \<equiv> {(s, s').
    \<comment> \<open>guards:\<close>
    guessed_runs Rb = \<lparr>role=Resp, owner=B, partner=A\<rparr> \<and>
    progress s Rb = Some {xny, xgnx, xgny, xsk} \<and>
    guessed_frame Rb xgnx = Some gnx \<and>
    (can_signal s A B \<longrightarrow> \<comment> \<open>authentication guard\<close>
      (\<exists> Ra. guessed_runs Ra = \<lparr>role=Init, owner=A, partner=B\<rparr> \<and>
             in_progressS (progress s Ra) {xnx, xgnx, xgny, xsk, xEnd} \<and>
             guessed_frame Ra xgnx = Some gnx \<and>
             guessed_frame Ra xgny = Some (Exp Gen (NonceF (Rb$ny))))) \<and>
    (Rb = test \<longrightarrow> Exp gnx (NonceF (Rb$ny)) \<notin> synth (analz (ik s))) \<and>

    \<comment> \<open>actions:\<close>
    s' = s\<lparr> progress := (progress s)(Rb \<mapsto> {xny, xgnx, xgny, xsk, xEnd}),
            secret := {x. x = Exp gnx (NonceF (Rb$ny)) \<and> Rb = test} \<union> secret s,
            signalsResp := if can_signal s A B then
                             addSignal (signalsResp s) (Commit A B (Exp gnx (NonceF (Rb$ny))))
                           else
                             signalsResp s
          \<rparr>
  }"


text \<open>Specification.\<close>

definition 
  l1_init :: "l1_state set"
where
  "l1_init \<equiv> { \<lparr>
    ik = {},
    secret = {},
    progress = empty,
    signalsInit = \<lambda>x. 0,
    signalsResp = \<lambda>x. 0
    \<rparr> }"

definition 
  l1_trans :: "('a l1_state_scheme * 'a l1_state_scheme) set" where
  "l1_trans \<equiv> (\<Union>m Ra Rb A B x.
     l1_step1 Ra A B \<union>
     l1_step2 Rb A B x \<union>
     l1_step3 Ra A B x \<union>
     l1_step4 Rb A B x \<union>
     l1_learn m \<union>
     Id
  )"

definition 
  l1 :: "(l1_state, l1_obs) spec" where
  "l1 \<equiv> \<lparr>
    init = l1_init,
    trans = l1_trans,
    obs = id
  \<rparr>"

lemmas l1_defs = 
  l1_def l1_init_def l1_trans_def
  l1_learn_def
  l1_step1_def l1_step2_def l1_step3_def l1_step4_def

lemmas l1_nostep_defs =
  l1_def l1_init_def l1_trans_def

lemma l1_obs_id [simp]: "obs l1 = id"
by (simp add: l1_def)


lemma run_ended_trans:
  "run_ended (progress s R) \<Longrightarrow>
   (s, s') \<in> trans l1 \<Longrightarrow>
   run_ended (progress s' R)"
apply (auto simp add: l1_nostep_defs)
apply (auto simp add: l1_defs ik_dy_def)
done

lemma can_signal_trans:
  "can_signal s' A B \<Longrightarrow>
  (s, s') \<in> trans l1 \<Longrightarrow>
  can_signal s A B"
by (auto simp add: can_signal_def run_ended_trans)


(**************************************************************************************************)
subsection \<open>Refinement: secrecy\<close>
(**************************************************************************************************)

text \<open>Mediator function.\<close>
definition 
  med01s :: "l1_obs \<Rightarrow> s0_obs"
where
  "med01s t \<equiv> \<lparr> ik = ik t, secret = secret t \<rparr>"


text \<open>Relation between states.\<close>
definition
  R01s :: "(s0_state * l1_state) set"
where
  "R01s \<equiv> {(s,s').
    s = \<lparr>ik = ik s', secret = secret s'\<rparr>
    }"


text \<open>Protocol independent events.\<close>

lemma l1_learn_refines_learn:
  "{R01s} s0_learn m, l1_learn m {>R01s}"
apply (simp add: PO_rhoare_defs R01s_def)
apply auto
apply (simp add: l1_defs s0_defs s0_secrecy_def)
done


text \<open>Protocol events.\<close>

lemma l1_step1_refines_skip:
  "{R01s} Id, l1_step1 Ra A B {>R01s}"
by (auto simp add: PO_rhoare_defs R01s_def l1_step1_def)

lemma l1_step2_refines_skip:
  "{R01s} Id, l1_step2 Rb A B gnx {>R01s}"
apply (auto simp add: PO_rhoare_defs R01s_def)
apply (auto simp add: l1_step2_def)
done

lemma l1_step3_refines_add_secret_skip:
  "{R01s} s0_add_secret (Exp gny (NonceF (Ra$nx))) \<union> Id, l1_step3 Ra A B gny {>R01s}"
apply (auto simp add: PO_rhoare_defs R01s_def s0_add_secret_def)
apply (auto simp add: l1_step3_def)
done

lemma l1_step4_refines_add_secret_skip:
  "{R01s} s0_add_secret (Exp gnx (NonceF (Rb$ny))) \<union> Id, l1_step4 Rb A B gnx {>R01s}"
apply (auto simp add: PO_rhoare_defs R01s_def s0_add_secret_def)
apply (auto simp add: l1_step4_def)
done

text \<open>Refinement proof.\<close>

lemmas l1_trans_refines_s0_trans = 
  l1_learn_refines_learn
  l1_step1_refines_skip l1_step2_refines_skip 
  l1_step3_refines_add_secret_skip l1_step4_refines_add_secret_skip

lemma l1_refines_init_s0 [iff]:
  "init l1 \<subseteq> R01s `` (init s0)"
by (auto simp add: R01s_def s0_defs l1_defs s0_secrecy_def)


lemma l1_refines_trans_s0 [iff]:
  "{R01s} trans s0, trans l1 {> R01s}"
by (auto simp add: s0_def l1_def s0_trans_def l1_trans_def 
         intro: l1_trans_refines_s0_trans)


lemma obs_consistent_med01x [iff]: 
  "obs_consistent R01s med01s s0 l1"
by (auto simp add: obs_consistent_def R01s_def med01s_def)



text \<open>Refinement result.\<close>
lemma l1s_refines_s0 [iff]: 
  "refines 
     R01s
     med01s s0 l1"
by (auto simp add:refines_def PO_refines_def)

lemma  l1_implements_s0 [iff]: "implements med01s s0 l1"
by (rule refinement_soundness) (fast)


(**************************************************************************************************)
subsection \<open>Derived invariants: secrecy\<close>
(**************************************************************************************************)

abbreviation "l1_secrecy \<equiv> s0_secrecy"


lemma l1_obs_secrecy [iff]: "oreach l1 \<subseteq> l1_secrecy"
apply (rule external_invariant_translation 
         [OF s0_obs_secrecy _ l1_implements_s0])
apply (auto simp add: med01s_def s0_secrecy_def)
done

lemma l1_secrecy [iff]: "reach l1 \<subseteq> l1_secrecy"
by (rule external_to_internal_invariant [OF l1_obs_secrecy], auto)


(**************************************************************************************************)
subsection \<open>Invariants: @{term "Init"} authenticates @{term "Resp"}\<close>
(**************************************************************************************************)

subsubsection \<open>inv1\<close>
(**************************************************************************************************)
text \<open>If an initiator commit signal exists for $(@{term "g"}^@{term "ny"})^@{term "Ra$nx"}$
  then @{term "Ra"} is
  @{term "Init"}, has passed step 3, and has @{text "(g^ny)^(Ra$nx)"} as the key in its frame.\<close>

definition
  l1_inv1 :: "l1_state set"
where
  "l1_inv1 \<equiv> {s. \<forall> Ra A B gny.
    signalsInit s (Commit A B (Exp gny (NonceF (Ra$nx)))) > 0 \<longrightarrow>
      guessed_runs Ra = \<lparr>role=Init, owner=A, partner=B\<rparr> \<and>
      progress s Ra = Some {xnx, xgnx, xgny, xsk, xEnd} \<and>
      guessed_frame Ra xsk = Some (Exp gny (NonceF (Ra$nx)))
   }"
  
lemmas l1_inv1I = l1_inv1_def [THEN setc_def_to_intro, rule_format]
lemmas l1_inv1E [elim] = l1_inv1_def [THEN setc_def_to_elim, rule_format]
lemmas l1_inv1D = l1_inv1_def [THEN setc_def_to_dest, rule_format, rotated 1, simplified]


lemma l1_inv1_init [iff]:
  "init l1 \<subseteq> l1_inv1"
by (auto simp add: l1_def l1_init_def l1_inv1_def)

lemma l1_inv1_trans [iff]:
  "{l1_inv1} trans l1 {> l1_inv1}"
apply (auto simp add: PO_hoare_defs l1_nostep_defs intro!: l1_inv1I)
apply (auto simp add: l1_defs ik_dy_def l1_inv1_def dest: Exp_Exp_Gen_inj2 [OF sym])
done

lemma PO_l1_inv1 [iff]: "reach l1 \<subseteq> l1_inv1"
by (rule inv_rule_basic) (auto)


subsubsection \<open>inv2\<close>
(**************************************************************************************************)
text \<open>If a @{term "Resp"} run @{term "Rb"} has passed step 2 then
      (if possible) an initiator running signal has been emitted.\<close>

definition
  l1_inv2 :: "l1_state set"
where
  "l1_inv2 \<equiv> {s. \<forall> gnx A B Rb.
    guessed_runs Rb = \<lparr>role=Resp, owner=B, partner=A\<rparr> \<longrightarrow>
    in_progressS (progress s Rb) {xny, xgnx, xgny, xsk} \<longrightarrow>
    guessed_frame Rb xgnx = Some gnx \<longrightarrow>
    can_signal s A B \<longrightarrow>
      signalsInit s (Running A B (Exp gnx (NonceF (Rb$ny)))) > 0
  }"

lemmas l1_inv2I = l1_inv2_def [THEN setc_def_to_intro, rule_format]
lemmas l1_inv2E [elim] = l1_inv2_def [THEN setc_def_to_elim, rule_format]
lemmas l1_inv2D = l1_inv2_def [THEN setc_def_to_dest, rule_format, rotated 1, simplified]


lemma l1_inv2_init [iff]:
  "init l1 \<subseteq> l1_inv2"
by (auto simp add: l1_def l1_init_def l1_inv2_def)

lemma l1_inv2_trans [iff]:
  "{l1_inv2} trans l1 {> l1_inv2}"
apply (auto simp add: PO_hoare_defs intro!: l1_inv2I)
apply (drule can_signal_trans, assumption)
apply (auto simp add: l1_nostep_defs)
apply (auto simp add: l1_defs ik_dy_def l1_inv2_def)
done

lemma PO_l1_inv2 [iff]: "reach l1 \<subseteq> l1_inv2"
by (rule inv_rule_basic) (auto)


subsubsection \<open>inv3 (derived)\<close>
(**************************************************************************************************)
text \<open>
If an @{term "Init"} run before step 3 and a @{term "Resp"} run after step 2 both know the same
half-keys (more or less), then the number of @{term "Init"} running signals for the key is strictly
greater than the number of @{term "Init"} commit signals.
(actually, there are 0 commit and 1 running).
\<close>

definition
  l1_inv3 :: "l1_state set"
where
  "l1_inv3 \<equiv> {s. \<forall> A B Rb Ra gny.
    guessed_runs Rb = \<lparr>role=Resp, owner=B, partner=A\<rparr> \<longrightarrow>
    in_progressS (progress s Rb) {xny, xgnx, xgny, xsk} \<longrightarrow>
    guessed_frame Rb xgny = Some gny \<longrightarrow>
    guessed_frame Rb xgnx = Some (Exp Gen (NonceF (Ra$nx))) \<longrightarrow>
    guessed_runs Ra = \<lparr>role=Init, owner=A, partner=B\<rparr> \<longrightarrow>
    progress s Ra = Some {xnx, xgnx} \<longrightarrow>
    can_signal s A B \<longrightarrow>
      signalsInit s (Commit A B (Exp gny (NonceF (Ra$nx)))) 
    < signalsInit s (Running A B (Exp gny (NonceF (Ra$nx)))) 
  }"

lemmas l1_inv3I = l1_inv3_def [THEN setc_def_to_intro, rule_format]
lemmas l1_inv3E [elim] = l1_inv3_def [THEN setc_def_to_elim, rule_format]
lemmas l1_inv3D = l1_inv3_def [THEN setc_def_to_dest, rule_format, rotated 1, simplified]

lemma l1_inv3_derived: "l1_inv1 \<inter> l1_inv2 \<subseteq> l1_inv3"
apply (auto intro!: l1_inv3I)
apply (auto dest!: l1_inv2D)
apply (rename_tac x A B Rb Ra)
apply (case_tac 
  "signalsInit x (Commit A B (Exp (Exp Gen (NonceF (Rb $ ny))) (NonceF (Ra $ nx)))) > 0", auto)
apply (fastforce dest: l1_inv1D elim: equalityE)
done
    
subsection \<open>Invariants: @{term "Resp"} authenticates @{term "Init"}\<close>
(**************************************************************************************************)

subsubsection \<open>inv4\<close>
(**************************************************************************************************)
text \<open>If a @{term "Resp"} commit signal exists for $(@{term "g"}^@{term "nx"})^@{term "Rb$ny"}$
  then @{term "Rb"} is @{term "Resp"}, has finished its run, and
  has $(@{term "g"}^@{term "nx"})^@{term "Rb$ny"}$ as the key in its frame.\<close>

definition
  l1_inv4 :: "l1_state set"
where
  "l1_inv4 \<equiv> {s. \<forall> Rb A B gnx.
    signalsResp s (Commit A B (Exp gnx (NonceF (Rb$ny)))) > 0 \<longrightarrow>
      guessed_runs Rb = \<lparr>role=Resp, owner=B, partner=A\<rparr> \<and>
      progress s Rb = Some {xny, xgnx, xgny, xsk, xEnd} \<and>
      guessed_frame Rb xgnx = Some gnx
   }"
  
lemmas l1_inv4I = l1_inv4_def [THEN setc_def_to_intro, rule_format]
lemmas l1_inv4E [elim] = l1_inv4_def [THEN setc_def_to_elim, rule_format]
lemmas l1_inv4D = l1_inv4_def [THEN setc_def_to_dest, rule_format, rotated 1, simplified]


lemma l1_inv4_init [iff]:
  "init l1 \<subseteq> l1_inv4"
by (auto simp add: l1_def l1_init_def l1_inv4_def)

declare domIff [iff]

lemma l1_inv4_trans [iff]:
  "{l1_inv4} trans l1 {> l1_inv4}"
apply (auto simp add: PO_hoare_defs l1_nostep_defs intro!: l1_inv4I)
apply (auto simp add: l1_inv4_def  l1_defs ik_dy_def dest: Exp_Exp_Gen_inj2 [OF sym])
done

declare domIff [iff del]

lemma PO_l1_inv4 [iff]: "reach l1 \<subseteq> l1_inv4"
by (rule inv_rule_basic) (auto)


subsubsection \<open>inv5\<close>
(**************************************************************************************************)
text \<open>If an @{term "Init"} run @{term "Ra"} has passed step3 then (if possible) a
       @{term "Resp"} running signal has been emitted.\<close>

definition
  l1_inv5 :: "l1_state set"
where
  "l1_inv5 \<equiv> {s. \<forall> gny A B Ra.
    guessed_runs Ra = \<lparr>role=Init, owner=A, partner=B\<rparr> \<longrightarrow>
    in_progressS (progress s Ra) {xnx, xgnx, xgny, xsk, xEnd} \<longrightarrow>
    guessed_frame Ra xgny = Some gny \<longrightarrow>
    can_signal s A B \<longrightarrow>
      signalsResp s (Running A B (Exp gny (NonceF (Ra$nx)))) > 0
  }"

lemmas l1_inv5I = l1_inv5_def [THEN setc_def_to_intro, rule_format]
lemmas l1_inv5E [elim] = l1_inv5_def [THEN setc_def_to_elim, rule_format]
lemmas l1_inv5D = l1_inv5_def [THEN setc_def_to_dest, rule_format, rotated 1, simplified]


lemma l1_inv5_init [iff]:
  "init l1 \<subseteq> l1_inv5"
by (auto simp add: l1_def l1_init_def l1_inv5_def)

lemma l1_inv5_trans [iff]:
  "{l1_inv5} trans l1 {> l1_inv5}"
apply (auto simp add: PO_hoare_defs intro!: l1_inv5I)
apply (drule can_signal_trans, assumption)
apply (auto simp add: l1_nostep_defs)
apply (auto simp add: l1_defs ik_dy_def l1_inv5_def)
done

lemma PO_l1_inv5 [iff]: "reach l1 \<subseteq> l1_inv5"
by (rule inv_rule_basic) (auto)


subsubsection \<open>inv6 (derived)\<close>
(**************************************************************************************************)
text \<open>If a @{term "Resp"} run before step 4 and an @{term "Init"} run after step 3 both know
  the same half-keys (more or less), then the number of @{term "Resp"} running signals
  for the key is strictly greater than the number of @{term "Resp"} commit signals.
  (actually, there are 0 commit and 1 running).
\<close>

definition
  l1_inv6 :: "l1_state set"
where
  "l1_inv6 \<equiv> {s. \<forall> A B Rb Ra gnx.
    guessed_runs Ra = \<lparr>role=Init, owner=A, partner=B\<rparr> \<longrightarrow>
    in_progressS (progress s Ra) {xnx, xgnx, xgny, xsk, xEnd} \<longrightarrow>
    guessed_frame Ra xgnx = Some gnx \<longrightarrow>
    guessed_frame Ra xgny = Some (Exp Gen (NonceF (Rb$ny))) \<longrightarrow>
    guessed_runs Rb = \<lparr>role=Resp, owner=B, partner=A\<rparr> \<longrightarrow>
    progress s Rb = Some {xny, xgnx, xgny, xsk} \<longrightarrow>
    can_signal s A B \<longrightarrow>
      signalsResp s (Commit A B (Exp gnx (NonceF (Rb$ny)))) 
    < signalsResp s (Running A B (Exp gnx (NonceF (Rb$ny)))) 
  }"

lemmas l1_inv6I = l1_inv6_def [THEN setc_def_to_intro, rule_format]
lemmas l1_inv6E [elim] = l1_inv6_def [THEN setc_def_to_elim, rule_format]
lemmas l1_inv6D = l1_inv6_def [THEN setc_def_to_dest, rule_format, rotated 1, simplified]

lemma l1_inv6_derived:
  "l1_inv4 \<inter> l1_inv5 \<subseteq> l1_inv6"
proof (auto intro!: l1_inv6I)
  fix s::l1_state fix A B Rb Ra
  assume HRun:"guessed_runs Ra = \<lparr>role = Init, owner = A, partner = B\<rparr>"
              "in_progressS (progress s Ra) {xnx, xgnx, xgny, xsk, xEnd}"
              "guessed_frame Ra xgny = Some (Exp Gen (NonceF (Rb $ ny)))"
              "can_signal s A B"
  assume HRb: "progress s Rb = Some {xny, xgnx, xgny, xsk}"
  assume I4:"s \<in> l1_inv4"
  assume I5:"s \<in> l1_inv5"
  from I4 HRb 
  have "signalsResp s (Commit A B (Exp (Exp Gen (NonceF (Rb $ ny))) (NonceF (Ra $ nx)))) > 0 
       \<Longrightarrow> False"
    proof (auto dest!: l1_inv4D)
      assume "{xny, xgnx, xgny, xsk, xEnd} = {xny, xgnx, xgny, xsk}"
      thus ?thesis by force
    qed
  then have 
    HC: "signalsResp s (Commit A B (Exp (Exp Gen (NonceF (Rb $ ny))) (NonceF (Ra $ nx)))) = 0"
    by auto
  from I5 HRun 
  have "signalsResp s (Running A B (Exp (Exp Gen (NonceF (Rb $ ny))) (NonceF (Ra $ nx)))) > 0"
    by (auto dest!: l1_inv5D)
  with HC show 
     "signalsResp s (Commit A B (Exp (Exp Gen (NonceF (Rb $ ny))) (NonceF (Ra $ nx))))
    < signalsResp s (Running A B (Exp (Exp Gen (NonceF (Rb $ ny))) (NonceF (Ra $ nx))))"
    by auto
qed


(**************************************************************************************************)
subsection \<open>Refinement: injective agreement  (@{term "Init"} authenticates @{term "Resp"})\<close>
(**************************************************************************************************)

text \<open>Mediator function.\<close>
definition 
  med01iai :: "l1_obs \<Rightarrow> a0i_obs"
where
  "med01iai t \<equiv> \<lparr>a0n_state.signals = signalsInit t\<rparr>"


text \<open>Relation between states.\<close>
definition
  R01iai :: "(a0i_state * l1_state) set"
where
  "R01iai \<equiv> {(s,s').
    a0n_state.signals s = signalsInit s'
    }"


text \<open>Protocol-independent events.\<close>

lemma l1_learn_refines_a0_ia_skip_i:
  "{R01iai} Id, l1_learn m {>R01iai}"
apply (auto simp add: PO_rhoare_defs R01iai_def)
apply (simp add: l1_learn_def)
done



text \<open>Protocol events.\<close>
lemma l1_step1_refines_a0i_skip_i:
  "{R01iai} Id, l1_step1 Ra A B {>R01iai}"
by (auto simp add: PO_rhoare_defs R01iai_def l1_step1_def)


lemma l1_step2_refines_a0i_running_skip_i:
  "{R01iai} a0i_running A B (Exp gnx (NonceF (Rb$ny))) \<union> Id, l1_step2 Rb A B gnx {>R01iai}"
by (auto simp add: PO_rhoare_defs R01iai_def, simp_all add: l1_step2_def a0i_running_def, auto)

lemma l1_step3_refines_a0i_commit_skip_i:
  "{R01iai \<inter> (UNIV \<times> l1_inv3)} 
     a0i_commit A B (Exp gny (NonceF (Ra$nx))) \<union> Id, 
     l1_step3 Ra A B gny 
   {>R01iai}"
apply (auto simp add: PO_rhoare_defs R01iai_def)
apply (auto simp add: l1_step3_def a0i_commit_def)
apply (force elim!: l1_inv3E)+
done

lemma l1_step4_refines_a0i_skip_i:
  "{R01iai} Id, l1_step4 Rb A B gnx {>R01iai}"
by (auto simp add: PO_rhoare_defs R01iai_def, auto simp add: l1_step4_def)

text \<open>Refinement proof.\<close>
lemmas l1_trans_refines_a0i_trans_i = 
  l1_learn_refines_a0_ia_skip_i
  l1_step1_refines_a0i_skip_i l1_step2_refines_a0i_running_skip_i
  l1_step3_refines_a0i_commit_skip_i l1_step4_refines_a0i_skip_i

lemma l1_refines_init_a0i_i [iff]:
  "init l1 \<subseteq> R01iai `` (init a0i)"
by (auto simp add: R01iai_def a0i_defs l1_defs)


lemma l1_refines_trans_a0i_i [iff]:
  "{R01iai \<inter> (UNIV \<times> (l1_inv1 \<inter> l1_inv2))} trans a0i, trans l1 {> R01iai}"
proof -
  let ?pre' = "R01iai \<inter> (UNIV \<times> l1_inv3)"
  show ?thesis (is "{?pre} ?t1, ?t2 {>?post}")
  proof (rule relhoare_conseq_left)
    show "?pre \<subseteq> ?pre'"
      using l1_inv3_derived by blast
  next 
    show "{?pre'} ?t1, ?t2 {> ?post}"
      apply (auto simp add: a0i_def l1_def a0i_trans_def l1_trans_def)
      prefer 2 using l1_step2_refines_a0i_running_skip_i apply (simp add: PO_rhoare_defs, blast)
      prefer 2 using l1_step3_refines_a0i_commit_skip_i apply (simp add: PO_rhoare_defs, blast)
      apply (blast intro!:l1_trans_refines_a0i_trans_i)+
      done
  qed
qed


lemma obs_consistent_med01iai [iff]: 
  "obs_consistent R01iai med01iai a0i l1"
by (auto simp add: obs_consistent_def R01iai_def med01iai_def)



text \<open>Refinement result.\<close>
lemma l1_refines_a0i_i [iff]: 
  "refines 
     (R01iai \<inter> (reach a0i \<times> (l1_inv1 \<inter> l1_inv2)))
     med01iai a0i l1"
by (rule Refinement_using_invariants, auto)

lemma  l1_implements_a0i_i [iff]: "implements med01iai a0i l1"
by (rule refinement_soundness) (fast)


(**************************************************************************************************)
subsection \<open>Derived invariants: injective agreement (@{term "Init"} authenticates @{term "Resp"})\<close>
(**************************************************************************************************)

definition 
  l1_iagreement_Init :: "('a l1_state_scheme) set"
where
  "l1_iagreement_Init \<equiv> {s. \<forall> A B N. 
     signalsInit s (Commit A B N) \<le> signalsInit s (Running A B N)
  }"

lemmas l1_iagreement_InitI = l1_iagreement_Init_def [THEN setc_def_to_intro, rule_format]
lemmas l1_iagreement_InitE [elim] = l1_iagreement_Init_def [THEN setc_def_to_elim, rule_format]


lemma l1_obs_iagreement_Init [iff]: "oreach l1 \<subseteq> l1_iagreement_Init"
apply (rule external_invariant_translation 
         [OF PO_a0i_obs_agreement _ l1_implements_a0i_i])
apply (auto simp add: med01iai_def l1_iagreement_Init_def a0i_agreement_def)
done

lemma l1_iagreement_Init [iff]: "reach l1 \<subseteq> l1_iagreement_Init"
by (rule external_to_internal_invariant [OF l1_obs_iagreement_Init], auto)


(**************************************************************************************************)
subsection \<open>Refinement: injective agreement  (@{term "Resp"} authenticates @{term "Init"})\<close>
(**************************************************************************************************)

text \<open>Mediator function.\<close>
definition 
  med01iar :: "l1_obs \<Rightarrow> a0i_obs"
where
  "med01iar t \<equiv> \<lparr>a0n_state.signals = signalsResp t\<rparr>"


text \<open>Relation between states.\<close>
definition
  R01iar :: "(a0i_state * l1_state) set"
where
  "R01iar \<equiv> {(s,s').
    a0n_state.signals s = signalsResp s'
    }"


text \<open>Protocol-independent events.\<close>

lemma l1_learn_refines_a0_ia_skip_r:
  "{R01iar} Id, l1_learn m {>R01iar}"
apply (auto simp add: PO_rhoare_defs R01iar_def)
apply (simp add: l1_learn_def)
done



text \<open>Protocol events.\<close>
lemma l1_step1_refines_a0i_skip_r:
  "{R01iar} Id, l1_step1 Ra A B {>R01iar}"
by (auto simp add: PO_rhoare_defs R01iar_def l1_step1_def)


lemma l1_step2_refines_a0i_skip_r:
  "{R01iar} Id, l1_step2 Rb A B gnx {>R01iar}"
by (auto simp add: PO_rhoare_defs R01iar_def, auto simp add:l1_step2_def)

lemma l1_step3_refines_a0i_running_skip_r:
  "{R01iar} a0i_running A B (Exp gny (NonceF (Ra$nx))) \<union> Id, l1_step3 Ra A B gny {>R01iar}"
by (auto simp add: PO_rhoare_defs R01iar_def, simp_all add: l1_step3_def a0i_running_def, auto)

lemma l1_step4_refines_a0i_commit_skip_r:
  "{R01iar \<inter> UNIV\<times>l1_inv6} 
     a0i_commit A B (Exp gnx (NonceF (Rb$ny))) \<union> Id, 
     l1_step4 Rb A B gnx 
   {>R01iar}"
apply (auto simp add: PO_rhoare_defs R01iar_def)
apply (auto simp add: l1_step4_def a0i_commit_def)
apply (auto dest!: l1_inv6D [rotated 1])
done

text \<open>Refinement proofs.\<close>
lemmas l1_trans_refines_a0i_trans_r = 
  l1_learn_refines_a0_ia_skip_r
  l1_step1_refines_a0i_skip_r l1_step2_refines_a0i_skip_r
  l1_step3_refines_a0i_running_skip_r l1_step4_refines_a0i_commit_skip_r

lemma l1_refines_init_a0i_r [iff]:
  "init l1 \<subseteq> R01iar `` (init a0i)"
by (auto simp add: R01iar_def a0i_defs l1_defs)


lemma l1_refines_trans_a0i_r [iff]:
  "{R01iar \<inter> (UNIV \<times> (l1_inv4 \<inter> l1_inv5))} trans a0i, trans l1 {> R01iar}"
proof -
  let ?pre' = "R01iar \<inter> (UNIV \<times> l1_inv6)"
  show ?thesis (is "{?pre} ?t1, ?t2 {>?post}")
  proof (rule relhoare_conseq_left)
    show "?pre \<subseteq> ?pre'"
      using l1_inv6_derived by blast
  next 
    show "{?pre'} ?t1, ?t2 {> ?post}"
      apply (auto simp add: a0i_def l1_def a0i_trans_def l1_trans_def)
      prefer 3 using l1_step3_refines_a0i_running_skip_r apply (simp add: PO_rhoare_defs, blast)
      prefer 3 using l1_step4_refines_a0i_commit_skip_r apply (simp add: PO_rhoare_defs, blast)
      apply (blast intro!:l1_trans_refines_a0i_trans_r)+
      done
  qed
qed


lemma obs_consistent_med01iar [iff]: 
  "obs_consistent R01iar med01iar a0i l1"
by (auto simp add: obs_consistent_def R01iar_def med01iar_def)


text \<open>Refinement result.\<close>

lemma l1_refines_a0i_r [iff]: 
  "refines 
     (R01iar \<inter> (reach a0i \<times> (l1_inv4 \<inter> l1_inv5)))
     med01iar a0i l1"
by (rule Refinement_using_invariants, auto)

lemma  l1_implements_a0i_r [iff]: "implements med01iar a0i l1"
by (rule refinement_soundness) (fast)


(**************************************************************************************************)
subsection \<open>Derived invariants: injective agreement (@{term "Resp"} authenticates @{term "Init"})\<close>
(**************************************************************************************************)

definition 
  l1_iagreement_Resp :: "('a l1_state_scheme) set"
where
  "l1_iagreement_Resp \<equiv> {s. \<forall> A B N. 
     signalsResp s (Commit A B N) \<le> signalsResp s (Running A B N)
  }"

lemmas l1_iagreement_RespI = l1_iagreement_Resp_def [THEN setc_def_to_intro, rule_format]
lemmas l1_iagreement_RespE [elim] = l1_iagreement_Resp_def [THEN setc_def_to_elim, rule_format]


lemma l1_obs_iagreement_Resp [iff]: "oreach l1 \<subseteq> l1_iagreement_Resp"
apply (rule external_invariant_translation 
         [OF PO_a0i_obs_agreement _ l1_implements_a0i_r])
apply (auto simp add: med01iar_def l1_iagreement_Resp_def a0i_agreement_def)
done

lemma l1_iagreement_Resp [iff]: "reach l1 \<subseteq> l1_iagreement_Resp"
by (rule external_to_internal_invariant [OF l1_obs_iagreement_Resp], auto)

end
