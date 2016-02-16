(*  Title:       List Factoring
    Author:      Max Haslbeck
*)
theory List_Factoring
imports
Partial_Cost_Model
MTF2_Effects
begin
term config
hide_const config compet



chapter "List factoring technique"


fun ALG :: "'a \<Rightarrow> 'a list \<Rightarrow> nat \<Rightarrow> ('a list * 'is) \<Rightarrow> nat" where
  "ALG x qs i s = (if x < (qs!i) in fst s then 1::nat else 0)" 
 

lemma befaf: "q\<in>set s \<Longrightarrow> distinct s \<Longrightarrow> before q s \<union> {q} \<union> after q s = set s"
proof -
  case goal1
  have "before q s \<union> {y. index s y = index s q \<and> q \<in> set s}
      = {y. index s y \<le> index s q \<and> q \<in> set s}"
        unfolding before_in_def apply(auto) by (simp add: le_neq_implies_less)
  also have "\<dots> =  {y. index s y \<le> index s q \<and> y\<in> set s \<and> q \<in> set s}"
    apply(auto) by (metis index_conv_size_if_notin index_less_size_conv not_less)
  also with `q \<in> set s` have "\<dots> = {y. index s y \<le> index s q \<and> y\<in> set s}" by auto
  finally have "before q s \<union> {y. index s y = index s q \<and> q \<in> set s} \<union> after q s
      = {y. index s y \<le> index s q \<and> y\<in> set s} \<union> {y. index s y > index s q \<and> y \<in> set s}"
      unfolding before_in_def by simp
  also have "\<dots> = set s" by auto
  finally show "before q s \<union> {q} \<union> after q s = set s" using goal1 by simp
qed


lemma index_sum: "distinct s \<Longrightarrow> q\<in>set s \<Longrightarrow> index s q = (\<Sum>e\<in>set s. if e < q in s then 1 else 0)"
proof - 
  case goal1

  then have bia_empty: "before q s \<inter> ({q} \<union> after q s) = {}"
    by(auto simp: before_in_def)

  from befaf[OF goal1(2) goal1(1)] have "(\<Sum>e\<in>set s. if e < q in s then 1::nat else 0)
    = (\<Sum>e\<in>(before q s \<union> {q} \<union> after q s). if e < q in s then 1 else 0)" by auto
  also have "\<dots> = (\<Sum>e\<in>before q s. if e < q in s then 1 else 0)
            + (\<Sum>e\<in>{q}. if e < q in s then 1 else 0) + (\<Sum>e\<in>after q s. if e < q in s then 1 else 0)"
   proof -
      have "(\<Sum>e\<in>(before q s \<union> {q} \<union> after q s). if e < q in s then 1::nat else 0)
      = (\<Sum>e\<in>(before q s \<union> ({q} \<union> after q s)). if e < q in s then 1::nat else 0)"
        by simp
      also have "\<dots> = (\<Sum>e\<in>before q s. if e < q in s then 1 else 0)
          + (\<Sum>e\<in>({q} \<union> after q s). if e < q in s then 1 else 0)
          - (\<Sum>e\<in>(before q s \<inter> ({q} \<union> after q s)). if e < q in s then 1 else 0)"
          apply(rule setsum_Un_nat) by(simp_all)
      also have "\<dots> = (\<Sum>e\<in>before q s. if e < q in s then 1 else 0)
          + (\<Sum>e\<in>({q} \<union> after q s). if e < q in s then 1 else 0)" using bia_empty by auto
      also have "\<dots> = (\<Sum>e\<in>before q s. if e < q in s then 1 else 0)
          + (\<Sum>e\<in>{q}. if e < q in s then 1 else 0) + (\<Sum>e\<in>after q s. if e < q in s then 1 else 0)"
          by (simp add: before_in_def)
      finally show ?thesis .
    qed
  also have "\<dots> = (\<Sum>e\<in>before q s. 1) + (\<Sum>e\<in>({q} \<union> after q s). 0)" apply(auto)
    unfolding before_in_def by auto
  also have "\<dots> = card (before q s)" by auto
  also have "\<dots> = card (set (take (index s q) s))" using before_conv_take[OF goal1(2)] by simp
  also have "\<dots> = length (take (index s q) s)" using distinct_card goal1(1) distinct_take by metis
  also have "\<dots> = min (length s) (index s q)" by simp
  also have "\<dots> = index s q" using index_le_size[of s q] by(auto)
  finally show ?thesis by simp
qed


(* no paid exchanges, requested items in state (nice, quickcheck is awesome!) *)
lemma t\<^sub>p_sumofALG: "distinct (fst s) \<Longrightarrow> snd a = [] \<Longrightarrow> (qs!i)\<in>set (fst s) 
    \<Longrightarrow> t\<^sub>p (fst s) (qs!i) a = (\<Sum>e\<in>set (fst s). ALG e qs i s)"
unfolding t\<^sub>p_def apply(simp add: split_def )
  using index_sum by metis

lemma t\<^sub>p_sumofALGreal: "distinct (fst s) \<Longrightarrow> snd a = [] \<Longrightarrow> (qs!i)\<in>set (fst s) 
  \<Longrightarrow> real(t\<^sub>p (fst s) (qs!i) a) = (\<Sum>e\<in>set (fst s). real(ALG e qs i s))"
proof -
  case goal1
  then have "real(t\<^sub>p (fst s) (qs!i) a) = real(\<Sum>e\<in>set (fst s). ALG e qs i s)"
    using t\<^sub>p_sumofALG by metis
  also have "\<dots> = (\<Sum>e\<in>set (fst s). real (ALG e qs i s))"
    by auto
  finally show ?case .
qed





(*
lemma fixes f :: "'a \<Rightarrow> 'a \<Rightarrow> nat"
  shows "setsum (setsum f A) B = setsum (setsum (\<lambda>a b. f b a) B) A"
*)


fun steps' where
  "steps' s _ _ 0 = s"
| "steps' s [] [] (Suc n) = s"
| "steps' s (q#qs) (a#as) (Suc n) = steps' (step s q a) qs as n"


lemma steps'_length: "length qs = length as \<Longrightarrow> length as = n
  \<Longrightarrow> length (steps' s qs as n) = length s"
apply(induct qs as arbitrary: s  n rule: list_induct2) by(auto simp: step_def)

lemma steps'_set: "length qs = length as \<Longrightarrow> length as = n
  \<Longrightarrow> set (steps' s qs as n) = set s"
apply(induct qs as arbitrary: s  n rule: list_induct2) by(auto simp: step_def)

lemma steps'_distinct2: "length qs = length as \<Longrightarrow> length as = n
  \<Longrightarrow>  distinct s \<Longrightarrow> distinct (steps' s qs as n)"
apply(induct qs as arbitrary: s  n rule: list_induct2) by(auto simp: distinct_step)


lemma steps'_distinct: "length qs = length as \<Longrightarrow> length as = n
  \<Longrightarrow> distinct (steps' s qs as n) = distinct s"
apply(induct qs as arbitrary: s  n rule: list_induct2) by(auto simp: distinct_step)

lemma steps'_dist_perm: "length qs = length as \<Longrightarrow> length as = n
  \<Longrightarrow> dist_perm s s \<Longrightarrow> dist_perm (steps' s qs as n) (steps' s qs as n)"
using steps'_set steps'_distinct by blast

lemma steps'_rests: "length qs = length as \<Longrightarrow> length as = n \<Longrightarrow> steps' s qs as n = steps' s (qs@r1) (as@r2) n" 
apply(induct qs as arbitrary: s  n rule: list_induct2) by auto

lemma steps'_append: "length qs = length as \<Longrightarrow> length qs = n \<Longrightarrow> steps' s (qs@[q]) (as@[a]) (Suc n) = step (steps' s qs as n) q a"
apply(induct qs as arbitrary: s  n rule: list_induct2) by auto



definition "ALG'_det Strat qs init i x = ALG x qs i (swaps (snd (Strat!i)) (steps' init qs Strat i),())"

lemma ALG'_det_append: "n < length Strat \<Longrightarrow> n < length qs \<Longrightarrow> ALG'_det Strat (qs@a) init n x 
                        = ALG'_det Strat qs init n x"
proof -
  assume qs: "n < length qs"
  assume S: "n < length Strat"

  have tt: "(qs @ a) ! n = qs ! n"
    using qs by (simp add: nth_append)

  have "steps' init (take n qs) (take n Strat) n = steps' init ((take n qs) @ drop n qs) ((take n Strat) @ (drop n Strat)) n"
       apply(rule steps'_rests)
        using S qs by auto
  then have A: "steps' init (take n qs) (take n Strat) n = steps' init qs Strat n" by auto
  have "steps' init (take n qs) (take n Strat) n = steps' init ((take n qs) @ ((drop n qs)@a)) ((take n Strat) @((drop n Strat)@[])) n"
       apply(rule steps'_rests)
        using S qs by auto
  then have B: "steps' init (take n qs) (take n Strat) n = steps' init (qs@a) (Strat@[]) n"
    by (metis append_assoc List.append_take_drop_id)
  from A B have "steps' init qs Strat n = steps' init (qs@a) (Strat@[]) n" by auto
  then have C: "steps' init qs Strat n = steps' init (qs@a) Strat n" by auto

  show ?thesis unfolding ALG'_det_def C
      unfolding ALG.simps tt by auto
qed 


abbreviation "config'' A qs init n == config_rand A init (take n qs)"

definition "ALG' A qs init i x = E( map_pmf (ALG x qs i) (config'' A qs init i))"
thm ALG'_def
lemma ALG'_refl: "qs!i = x \<Longrightarrow> ALG' A qs init i x = 0"
unfolding ALG'_def by(simp add: split_def before_in_def)
 

definition ALGxy_det where
  "ALGxy_det A qs init x y = (\<Sum>i\<in>{i. i<length qs}. (if (qs!i \<in> {y,x}) then ALG'_det A qs init i y + ALG'_det A qs init i x
                                                    else 0::nat))"

lemma ALGxy_det_alternativ: "ALGxy_det A qs init x y
   =  (\<Sum>i\<in>{i. i<length qs \<and> (qs!i \<in> {y,x})}. ALG'_det A qs init i y + ALG'_det A qs init i x)"
proof -
  thm setsum.inter_restrict
  have e: "{i. i<length qs \<and> (qs!i \<in> {y,x})} = {i. i<length qs} \<inter> {i. (qs!i \<in> {y,x})}"
      by auto
  have "(\<Sum>i\<in>{i. i<length qs \<and> (qs!i \<in> {y,x})}. ALG'_det A qs init i y + ALG'_det A qs init i x)
    = (\<Sum>i\<in>{i. i<length qs} \<inter> {i. (qs!i \<in> {y,x})}. ALG'_det A qs init i y + ALG'_det A qs init i x)"
    unfolding e by simp
  also have "\<dots> = (\<Sum>i\<in>{i. i<length qs}. (if i \<in> {i. (qs!i \<in> {y,x})} then ALG'_det A qs init i y + ALG'_det A qs init i x
                                                    else 0))"
    apply(rule setsum.inter_restrict) by auto
  also have "\<dots> = ALGxy_det A qs init x y"
    unfolding ALGxy_det_def by auto
  finally show ?thesis by simp
qed
    
definition ALGxy where
  "ALGxy A qs init x y = (\<Sum>i\<in>{i. i<length qs \<and> (qs!i \<in> {y,x})}. ALG' A qs init i y + ALG' A qs init i x)"



lemma ALGxy_append: "ALGxy A (rs@[r]) init x y =
      ALGxy A rs init x y + (if (r \<in> {y,x}) then ALG' A (rs@[r]) init (length rs) y + ALG' A (rs@[r]) init (length rs) x else 0 )" 
proof -
    have "ALGxy A (rs@[r]) init x y = (\<Sum>i\<in>{..<Suc (length rs)} \<inter> {i. (rs @ [r]) ! i \<in> {y, x}}.
       ALG' A (rs @ [r]) init i y +
       ALG' A (rs @ [r]) init i x)"sorry
    show ?thesis sorry
qed

lemma ALGxy_wholerange: "ALGxy A qs init x y
    = (\<Sum>i<(length qs). (if qs ! i \<in> {y, x}
          then ALG' A qs init i y + ALG' A qs init i x
          else 0 ))"
proof -
  have "ALGxy A qs init x y
      = (\<Sum>i\<in> {i. i < length qs} \<inter> {i. qs ! i \<in> {y, x}}.
       ALG' A qs init i y + ALG' A qs init i x)"
        unfolding ALGxy_def
        apply(rule setsum.cong)
          apply(simp) apply(blast) 
          by simp 
  also have "\<dots> = (\<Sum>i\<in>{i. i < length qs}.  if i \<in> {i. qs ! i \<in> {y, x}}
                                    then ALG' A qs init i y + ALG' A qs init i x 
                                    else 0)"
              by(rule setsum.inter_restrict) simp
  also have "\<dots> = (\<Sum>i<(length qs). (if qs ! i \<in> {y, x}
          then ALG' A qs init i y + ALG' A qs init i x
          else 0 ))" apply(rule setsum.cong) by(auto)
  finally show ?thesis .
qed
  
lemma umformung:
  fixes A :: "(('a::linorder) list,'is,'a,(nat * nat list)) alg_on_rand"
  assumes no_paid: "\<And>is s q. \<forall>((free,paid),_) \<in> (snd A (s,is) q). paid=[]"
  assumes inlist: "set qs \<subseteq> set init"
  assumes dist: "distinct init"
  assumes "\<And>x. x < length qs \<Longrightarrow> finite (set_pmf (config'' A qs init x))"
  shows "T\<^sub>p_on_rand A init qs = 
    (\<Sum>(x,y)\<in>{(x,y). x \<in> set init \<and> y\<in>set init \<and> x<y}. ALGxy A qs init x y)"
proof -
  have config_dist: "\<forall>n. \<forall>xa \<in> set_pmf (config'' A qs init n). distinct (fst xa)"
      using dist config_rand_distinct by metis

  thm setsum.cong
  have E0: "T\<^sub>p_on_rand A init qs =
        (\<Sum>i\<in>{..<length qs}. T\<^sub>p_on_rand_n A init qs i)" unfolding T_on_rand_as_sum by auto
  also have "\<dots> = 
  (\<Sum>i<length qs.  E (bind_pmf (config'' A qs init i)
                          (\<lambda>s. bind_pmf (snd A s (qs ! i))
                            (\<lambda>(a, nis). return_pmf (real (\<Sum>x\<in>set init. ALG x qs i s))))))"
    apply(rule setsum.cong)
      apply(simp)
      apply(simp add: bind_return_pmf bind_assoc_pmf)
      apply(rule arg_cong[where f=E]) 
          apply(rule bind_pmf_cong)
            apply(simp)
              apply(rule bind_pmf_cong)
                apply(simp)
                apply(simp add: split_def)
                  apply(subst t\<^sub>p_sumofALGreal)
                  proof (goal_cases)
                    case 1
                    then show ?case using config_dist by(metis)
                  next
                    case (2 a b c)
                    then show ?case using no_paid[of "fst b" "snd b"] by(auto simp add: split_def)
                  next
                    case (3 a b c)
                    with config_rand_set have a: "set (fst b) = set init" by metis
                    with inlist have " set qs \<subseteq> set (fst b)" by auto
                    with 3 show ?case by auto 
                  next
                    case (4 a b c)
                    with config_rand_set have a: "set (fst b) = set init" by metis
                    then show ?case by(simp) 
                  qed
          

          (* hier erst s, dann init *)
   also have "\<dots> = (\<Sum>i<length qs.
               E (map_pmf (\<lambda>(is, s). (real (\<Sum>x\<in>set init. ALG x qs i (is,s))))
                           (config'' A qs init i)))" 
                   apply(simp only: map_pmf_def split_def) by simp 
   also have E1: "\<dots> = (\<Sum>i<length qs. (\<Sum>x\<in>set init. ALG' A qs init i x))"
        apply(rule setsum.cong)
          apply(simp) 
            apply(simp add: split_def ALG'_def)
             apply(rule E_linear_setsum_allg)
              by(rule assms(4)) 
   also have E2: "\<dots> = (\<Sum>x\<in>set init.
          (\<Sum>i<length qs. ALG' A qs init i x))"
          by(rule setsum.commute) (* die summen tauschen *)
   also have E3: "\<dots> = (\<Sum>x\<in>set init.
          (\<Sum>y\<in>set init.
            (\<Sum>i\<in>{i. i<length qs \<and> qs!i=y}. ALG' A qs init i x)))"
            proof (rule setsum.cong)
              case goal2
              have "(\<Sum>i<length qs. ALG' A qs init i x)
                = setsum (%i. ALG' A qs init i x) {i. i<length qs}"
                  by (metis Collect_cong lessThan_def)
              also have "\<dots> = setsum (%i. ALG' A qs init i x) 
                        (UNION {y. y\<in> set init} (\<lambda>y. {i. i<length qs \<and> qs ! i = y}))"
                         apply(rule setsum.cong)
                         proof -
                          case goal1                          
                          show ?case apply(auto) using inlist by auto
                         qed simp
              also have "\<dots> = setsum (%t. setsum (%i. ALG' A qs init i x) {i. i<length qs \<and> qs ! i = t}) {y. y\<in> set init}"
                apply(rule setsum.UNION_disjoint)
                  apply(simp_all) by force
              also have "\<dots> = (\<Sum>y\<in>set init. \<Sum>i | i < length qs \<and> qs ! i = y.
                       ALG' A qs init i x)" by auto                  
             finally show ?case .
            qed (simp)
              
   also have "\<dots> = (\<Sum>(x,y)\<in> (set init \<times> set init).
            (\<Sum>i\<in>{i. i<length qs \<and> qs!i=y}. ALG' A qs init i x))"
       by (rule setsum.cartesian_product)
   also have "\<dots> = (\<Sum>(x,y)\<in> {(x,y). x\<in>set init \<and> y\<in> set init}.
            (\<Sum>i\<in>{i. i<length qs \<and> qs!i=y}. ALG' A qs init i x))"
            by simp
    also have E4: "\<dots> = (\<Sum>(x,y)\<in>{(x,y). x\<in>set init \<and> y\<in> set init \<and> x\<noteq>y}.
            (\<Sum>i\<in>{i. i<length qs \<and> qs!i=y}. ALG' A qs init i x))" (is "(\<Sum>(x,y)\<in> ?L. ?f x y) = (\<Sum>(x,y)\<in> ?R. ?f x y)")
      proof -
        case goal1
        let ?M = "{(x,y). x\<in>set init \<and> y\<in> set init \<and> x=y}"
        have A: "?L = ?R \<union> ?M" by auto
        have B: "{} = ?R \<inter> ?M" by auto
        thm ALG'_refl
        have "(\<Sum>(x,y)\<in> ?L. ?f x y) = (\<Sum>(x,y)\<in> ?R \<union> ?M. ?f x y)"
          by(simp only: A)
        also have "\<dots> = (\<Sum>(x,y)\<in> ?R. ?f x y) + (\<Sum>(x,y)\<in> ?M. ?f x y)"
            apply(rule setsum.union_disjoint)
              apply(rule finite_subset[where B="set init \<times> set init"])
                apply(auto)
              apply(rule finite_subset[where B="set init \<times> set init"])
                by(auto)
        also have "(\<Sum>(x,y)\<in> ?M. ?f x y) = 0"
          apply(rule setsum.neutral)
            by (auto simp add: ALG'_refl) 
        finally show ?case by simp
      qed

   also have "\<dots> = (\<Sum>(x,y)\<in>{(x,y). x \<in> set init \<and> y\<in>set init \<and> x<y}.
            (\<Sum>i\<in>{i. i<length qs \<and> qs!i=y}. ALG' A qs init i x)
           + (\<Sum>i\<in>{i. i<length qs \<and> qs!i=x}. ALG' A qs init i y) )"
            (is "(\<Sum>(x,y)\<in> ?L. ?f x y) = (\<Sum>(x,y)\<in> ?R. ?f x y +  ?f y x)")
              proof -
              case goal1
                let ?R' = "{(x,y). x \<in> set init \<and> y\<in>set init \<and> y<x}"
                have A: "?L = ?R \<union> ?R'" by auto
                have "{} = ?R \<inter> ?R'" by auto
                have C: "?R' = (%(x,y). (y, x)) ` ?R" by auto

                have D: "(\<Sum>(x,y)\<in> ?R'. ?f x y) = (\<Sum>(x,y)\<in> ?R. ?f y x)"
                proof -
                  case goal1
                  have "(\<Sum>(x,y)\<in> ?R'. ?f x y) = (\<Sum>(x,y)\<in> (%(x,y). (y, x)) ` ?R. ?f x y)"
                      by(simp only: C)
                  also have "(\<Sum>z\<in> (%(x,y). (y, x)) ` ?R. (%(x,y). ?f x y) z) = (\<Sum>z\<in>?R. ((%(x,y). ?f x y) \<circ> (%(x,y). (y, x))) z)"
                    apply(rule setsum.reindex)
                      by(fact swap_inj_on)
                  also have "\<dots> = (\<Sum>z\<in>?R. (%(x,y). ?f y x) z)"
                    apply(rule setsum.cong)
                      by(auto)
                  finally show ?thesis .                  
              qed

                thm setsum.union_disjoint
                have "(\<Sum>(x,y)\<in> ?L. ?f x y) = (\<Sum>(x,y)\<in> ?R \<union> ?R'. ?f x y)"
                  by(simp only: A) 
                also have "\<dots> = (\<Sum>(x,y)\<in> ?R. ?f x y) + (\<Sum>(x,y)\<in> ?R'. ?f x y)"
                  apply(rule setsum.union_disjoint) 
                    apply(rule finite_subset[where B="set init \<times> set init"])
                      apply(auto)
                    apply(rule finite_subset[where B="set init \<times> set init"])
                      by(auto)
                also have "\<dots> = (\<Sum>(x,y)\<in> ?R. ?f x y) + (\<Sum>(x,y)\<in> ?R. ?f y x)"
                    by(simp only: D)                  
                also have "\<dots> = (\<Sum>(x,y)\<in> ?R. ?f x y + ?f y x)"
                  by(simp add: split_def setsum.distrib[symmetric])
              finally show ?thesis .
            qed
                
   also have E5: "\<dots> = (\<Sum>(x,y)\<in>{(x,y). x \<in> set init \<and> y\<in>set init \<and> x<y}.
            (\<Sum>i\<in>{i. i<length qs \<and> (qs!i=y \<or> qs!i=x)}. ALG' A qs init i y + ALG' A qs init i x))"
    apply(rule setsum.cong)
      apply(simp)
      proof -
        case goal1
        then obtain a b where x: "x=(a,b)" and a: "a \<in> set init" "b \<in> set init" "a < b" by auto
        then have "a\<noteq>b" by simp
        then have disj: "{i. i < length qs \<and> qs ! i = b} \<inter> {i. i < length qs \<and> qs ! i = a} = {}" by auto
        have unio: "{i. i < length qs \<and> (qs ! i = b \<or> qs ! i = a)}
            = {i. i < length qs \<and> qs ! i = b} \<union> {i. i < length qs \<and> qs ! i = a}" by auto
        have "(\<Sum>i\<in>{i. i < length qs \<and> qs ! i = b} \<union>
          {i. i < length qs \<and> qs ! i = a}. ALG' A qs init i b +
               ALG' A qs init i a)
               = (\<Sum>i\<in>{i. i < length qs \<and> qs ! i = b}. ALG' A qs init i b +
               ALG' A qs init i a) + (\<Sum>i\<in>
          {i. i < length qs \<and> qs ! i = a}. ALG' A qs init i b +
               ALG' A qs init i a) - (\<Sum>i\<in>{i. i < length qs \<and> qs ! i = b} \<inter>
          {i. i < length qs \<and> qs ! i = a}. ALG' A qs init i b +
               ALG' A qs init i a) "
               apply(rule setsum_Un)
                by(auto)
        also have "\<dots> = (\<Sum>i\<in>{i. i < length qs \<and> qs ! i = b}. ALG' A qs init i b +
               ALG' A qs init i a) + (\<Sum>i\<in>
          {i. i < length qs \<and> qs ! i = a}. ALG' A qs init i b +
               ALG' A qs init i a)" using disj by auto
        also have "\<dots> = (\<Sum>i\<in>{i. i < length qs \<and> qs ! i = b}. ALG' A qs init i a)
         + (\<Sum>i\<in>{i. i < length qs \<and> qs ! i = a}. ALG' A qs init i b)"
          by (auto simp: ALG'_refl)
        finally 
            show ?case unfolding x apply(simp add: split_def)
          unfolding unio by simp
     qed   
     also have E6: "\<dots> = (\<Sum>(x,y)\<in>{(x,y). x \<in> set init \<and> y\<in>set init \<and> x<y}.
                  ALGxy A qs init x y)"
           unfolding ALGxy_def by simp
     finally show ?thesis . 
qed (* das ist gleichung 1.4 *)


thm umformung



lemma before_in_index1:
  fixes l
  assumes "set l = {x,y}" and "length l = 2" and "x\<noteq>y"
  shows "(if (x < y in l) then 0 else 1) = index l x"
unfolding before_in_def
proof (auto) (* bad style! *)
  case goal1
  from assms(1) have "index l y < length l" by simp
  with assms(2) goal1(1) show "index l x = 0" by auto
next
  case goal2
  from assms(1) have a: "index l x < length l" by simp
  from assms(1,3) have "index l y \<noteq> index l x" by simp
  with assms(2) goal2(1) a show "Suc 0 = index l x" by simp
qed (simp add: assms)


lemma before_in_index2:
  fixes l
  assumes "set l = {x,y}" and "length l = 2" and "x\<noteq>y"
  shows "(if (x < y in l) then 1 else 0) = index l y"
unfolding before_in_def
proof (auto) (* bad style! *)
  case goal2
  from assms(1,3) have a: "index l y \<noteq> index l x" by simp
  from assms(1) have "index l x < length l" by simp
  with assms(2) a goal2(1) show "index l y = 0" by auto
next
  case goal1
  from assms(1) have a: "index l y < length l" by simp
  from assms(1,3) have "index l y \<noteq> index l x" by simp
  with assms(2) goal1(1) a show "Suc 0 = index l y" by simp
qed (simp add: assms)


lemma before_in_index:
  fixes l
  assumes "set l = {x,y}" and "length l = 2" and "x\<noteq>y"
  shows "(x < y in l) = (index l x = 0)"
unfolding before_in_def
proof (safe)
  case goal1
  from assms(1) have "index l y < length l" by simp
  with assms(2) goal1(1) show "index l x = 0" by auto
next
  case goal2
  from assms(1,3) have "index l y \<noteq> index l x" by simp
  with goal2(1) show "index l x < index l y" by simp
qed (simp add: assms)





subsection "The pairwise property"

(*<*)


(* alternative definitionen die auch richtig sein müssten
fun ALGxy_n' where
  "ALGxy_n' A qs init n x y =  (if qs!n = x \<or> qs!n = y
      then E( map_pmf (ALG x qs n) (config\<^sub>p A qs init n))
        + E( map_pmf (ALG y qs n) (config\<^sub>p A qs init n))
      else 0)"
 
fun ALGxy' where
  "ALGxy' A qs init x y = (\<Sum>i<length qs. ALGxy_n' A qs init i x y)"

lemma "ALGxy A qs init x y  = ALGxy' A qs init x y " 
unfolding ALGxy_def ALG'_def sorry
 *)


definition pairwise where
  "pairwise A = (\<forall>init. distinct init \<longrightarrow> (\<forall>qs\<in>{xs. set xs \<subseteq> set init}. \<forall>(x::('a::linorder),y)\<in>{(x,y). x \<in> set init \<and> y\<in>set init \<and> x<y}. T\<^sub>p_on_rand A (Lxy init {x,y}) (Lxy qs {x,y}) = ALGxy A qs init x y))"
  
definition "Pbefore_in x y A qs init = map_pmf (\<lambda>p. x < y in fst p) (config_rand A init qs)"
 

lemma T_on_n_no_paid:
      assumes 
      nopaid: "\<And>l m n. map_pmf (\<lambda>x. snd (fst x)) (snd A (l, m) n) = return_pmf []" 
      shows "T_on_rand_n A init qs i = E (config'' A qs init i \<bind> (\<lambda>p. return_pmf (real(index (fst p) (qs ! i)))))"
proof -
  { fix p :: "'a list \<times> 'b"
    have "snd A (fst p,snd p)
       (qs ! i) \<bind>
      (\<lambda>pa. return_pmf
             (real(index
               (swaps (snd (fst pa))
                 (fst p))
               (qs ! i) +
              length (snd (fst pa)))))
           =  map_pmf ((%pay. 
             real(index (swaps pay (fst p))
               (qs ! i) + length pay)) \<circ> (\<lambda>pa. (snd(fst pa)) ))
               (snd A(fst p,snd p) (qs ! i))"
               by(simp add: map_pmf_def)
     also have "\<dots> = map_pmf (%pay. 
             (index (swaps pay (fst p))
               (qs ! i) + length pay)) (
                map_pmf ((\<lambda>pa. (snd(fst pa)) ))
               (snd A(fst p,snd p) (qs ! i)))"
              using pmf.map_comp by metis 
     also have "\<dots> = return_pmf (index (fst p) (qs ! i))" using nopaid[of "fst p" "snd p"]  by(auto)
     finally have "snd A(fst p,snd p)
       (qs ! i) \<bind>
      (\<lambda>pa. return_pmf
             (real(index
               (swaps (snd (fst pa))
                 (fst p))
               (qs ! i)) +
              length (snd (fst pa))))
                = return_pmf (real(index (fst p) (qs ! i)))" by auto
      } note brutal=this 
  show ?thesis 
    apply(simp add: t\<^sub>p_def split_def) 
      using brutal  by(simp)
qed
 
lemma pairwise_property_lemma:
  assumes  
relativeorder: "(\<And>init qs. distinct init \<Longrightarrow> qs \<in> {xs. set xs \<subseteq> set init}
    \<Longrightarrow> (\<And>x y. (x,y)\<in> {(x,y). x \<in> set init \<and> y\<in>set init \<and> x\<noteq>y} 
                \<Longrightarrow> x \<noteq> y
                \<Longrightarrow> Pbefore_in x y A qs init = Pbefore_in x y A (Lxy qs {x,y}) (Lxy init {x,y})
        ))" 
and nopaid: "\<And>xa r. \<forall>z\<in> set_pmf(snd A xa r). snd(fst z) = []"
shows "pairwise A"
unfolding pairwise_def
proof clarify
  case (goal1 init rs x y)
  then have xny: "x\<noteq>y" by auto

  note dinit=goal1(1)
  then have dLyx: "distinct (Lxy init {y,x})" by(rule Lxy_distinct)
  from dinit have dLxy: "distinct (Lxy init {x,y})" by(rule Lxy_distinct)
  have setLxy: "set (Lxy init {x, y}) = {x,y}" apply(subst Lxy_set_filter) using goal1 by auto
  have setLyx: "set (Lxy init {y, x}) = {x,y}" apply(subst Lxy_set_filter) using goal1 by auto
  have lengthLyx:" length  (Lxy init {y, x}) = 2" using setLyx distinct_card[OF dLyx] xny by simp
  have lengthLxy:" length  (Lxy init {x, y}) = 2" using setLxy distinct_card[OF dLxy] xny by simp
  have aee: "{x,y} = {y,x}" by auto


  from goal1(2) show ?case
    proof(induct rs rule: rev_induct)
      case (snoc r rs)
      
      have b: "Pbefore_in x y A rs init = Pbefore_in x y A (Lxy rs {x,y}) (Lxy init {x,y})"
        apply(rule relativeorder)
        using snoc goal1 xny by(simp_all)  

      show ?case (is "?L (rs @ [r]) = ?R (rs @ [r])")
      proof(cases "r\<in>{x,y}")
        case True
        note xyrequest=this
        let ?expr = "E (Partial_Cost_Model.config'_rand A
        (fst A (Lxy init {x, y}) \<bind>
         (\<lambda>is. return_pmf (Lxy init {x, y}, is)))
        (Lxy rs {x, y}) \<bind>
       (\<lambda>s. snd A s r \<bind>
            (\<lambda>(a, is').
                return_pmf
                 (real (t\<^sub>p (fst s) r a)))))"
        let ?expr2 = "ALG' A (rs @ [r]) init (length rs) y + ALG' A (rs @ [r]) init (length rs) x"

        from xyrequest have "?L (rs @ [r]) = ?L rs + ?expr"
          by(simp add: Lxy_snoc T_on_rand'_append)
        also have "\<dots> = ?L rs + ?expr2"
          proof(cases "r=x") 
            case True
            let ?projS ="config'_rand A (fst A (Lxy init {x, y}) \<bind> (\<lambda>is. return_pmf (Lxy init {x, y}, is))) (Lxy rs {x, y})"
            let ?S = "(config'_rand A (fst A init \<bind> (\<lambda>is. return_pmf (init, is))) rs)"


            have "?projS \<bind> (\<lambda>s. snd A s r
                           \<bind> (\<lambda>(a, is'). return_pmf (real (t\<^sub>p (fst s) r a))))
              = ?projS \<bind> (\<lambda>s. return_pmf (real (index (fst s) r)))"
                    proof (rule bind_pmf_cong)
                      case (goal2 z)
                      have "snd A z r \<bind> (\<lambda>(a, is'). return_pmf (real (t\<^sub>p (fst z) r a))) = snd A z r \<bind> (\<lambda>x. return_pmf (real (index (fst z) r)))"  
                        apply(rule bind_pmf_cong)
                          apply(simp)
                          using nopaid[of z r] by(simp add: split_def t\<^sub>p_def) 
                      then show ?case by(simp add: bind_return_pmf)
                    qed simp
            also have "\<dots> = map_pmf (%b. (if b then 0::real else 1)) (Pbefore_in x y A (Lxy rs {x,y}) (Lxy init {x,y}))"
                  unfolding Pbefore_in_def map_pmf_def
                    apply(simp add: bind_return_pmf bind_assoc_pmf)
                    apply(rule bind_pmf_cong)
                      apply(simp add: aee)
                      proof -
                        case (goal1 z)
                        have " (if x < y in fst z then 0 else 1) = (index (fst z) x)"
                            apply(rule before_in_index1)
                              using goal1 config_rand_set setLxy apply fast
                              using goal1 config_rand_length lengthLxy apply metis                 
                              using xny by simp
                        with True show ?case
                          by(auto)
                      qed
            also have "\<dots> = map_pmf (%b. (if b then 0::real else 1)) (Pbefore_in x y A rs init)" by(simp add: b)
                      
            also have "\<dots> = map_pmf (\<lambda>xa. real (if y < x in fst xa then 1 else 0)) ?S"  
                apply(simp add: Pbefore_in_def map_pmf_comp)
                proof (rule map_pmf_cong)
                  case (goal2 z)
                  then have set_z: "set (fst z) = set init"
                    using config_rand_set by fast
                  have "(\<not> x < y in fst z) = y < x in fst z" 
                    apply(subst not_before_in)
                      using set_z goal1(3,4) xny by(simp_all)
                  then show ?case by(simp add: )
                qed simp 
            finally have a: "?projS \<bind> (\<lambda>s. snd A s x
                           \<bind> (\<lambda>(a, is'). return_pmf (real (t\<^sub>p (fst s) x a))))
                  = map_pmf (\<lambda>xa. real (if y < x in fst xa then 1 else 0)) ?S" using True by simp
            from True show ?thesis
            apply(simp add: ALG'_refl nth_append)
            unfolding ALG'_def
              by(simp add: a)
          next
            case False
            with xyrequest have request: "r=y" by blast

            let ?projS ="config'_rand A (fst A (Lxy init {x, y}) \<bind> (\<lambda>is. return_pmf (Lxy init {x, y}, is))) (Lxy rs {x, y})"
            let ?S = "(config'_rand A (fst A init \<bind> (\<lambda>is. return_pmf (init, is))) rs)"


            have "?projS \<bind> (\<lambda>s. snd A s r
                           \<bind> (\<lambda>(a, is'). return_pmf (real (t\<^sub>p (fst s) r a))))
              = ?projS \<bind> (\<lambda>s. return_pmf (real (index (fst s) r)))"
                    proof (rule bind_pmf_cong)
                      case (goal2 z)
                      have "snd A z r \<bind> (\<lambda>(a, is'). return_pmf (real (t\<^sub>p (fst z) r a))) = snd A z r \<bind> (\<lambda>x. return_pmf (real (index (fst z) r)))"  
                        apply(rule bind_pmf_cong)
                          apply(simp)
                          using nopaid[of z r] by(simp add: split_def t\<^sub>p_def) 
                      then show ?case by(simp add: bind_return_pmf)
                    qed simp
            also have "\<dots> = map_pmf (%b. (if b then 1::real else 0)) (Pbefore_in x y A (Lxy rs {x,y}) (Lxy init {x,y}))"
                  unfolding Pbefore_in_def map_pmf_def
                    apply(simp add: bind_return_pmf bind_assoc_pmf)
                    apply(rule bind_pmf_cong)
                      apply(simp add: aee)
                      proof -
                        case (goal1 z)
                        have " (if x < y in fst z then 1 else 0) = (index (fst z) y)"
                            apply(rule before_in_index2)
                              using goal1 config_rand_set setLxy apply fast
                              using goal1 config_rand_length lengthLxy apply metis                 
                              using xny by simp
                        with request show ?case
                          by(auto)
                      qed
            also have "\<dots> = map_pmf (%b. (if b then 1::real else 0)) (Pbefore_in x y A rs init)" by(simp add: b)
                      
            also have "\<dots> = map_pmf (\<lambda>xa. real (if x < y in fst xa then 1 else 0)) ?S"  
                apply(simp add: Pbefore_in_def map_pmf_comp)
                apply (rule map_pmf_cong) by simp_all 
            finally have a: "?projS \<bind> (\<lambda>s. snd A s y
                           \<bind> (\<lambda>(a, is'). return_pmf (real (t\<^sub>p (fst s) y a))))
                  = map_pmf (\<lambda>xa. real (if x < y in fst xa then 1 else 0)) ?S" using request by simp
            from request show ?thesis
            apply(simp add: ALG'_refl nth_append)
            unfolding ALG'_def
              by(simp add: a) 
          qed            
        also have "\<dots> = ?R rs + ?expr2" using snoc by simp 
        also from True have "\<dots> = ?R (rs@[r])"
            apply(subst ALGxy_append) by(auto)
        finally show ?thesis .
      next
        case False
        then have "?L (rs @ [r]) = ?L rs" apply(subst Lxy_snoc) by simp
        also have "\<dots> = ?R rs" using snoc by(simp)
        also have "\<dots> = ?R (rs @ [r])"  
            apply(subst ALGxy_append) using False by(simp)
        finally show ?thesis .
      qed
    qed (simp add: ALGxy_def)
qed


lemma umf_pair: assumes
   0: "pairwise A"
  assumes 1: "\<And>is s q. \<forall>((free,paid),_) \<in> (snd A (s, is) q). paid=[]"
  assumes 2: "set qs \<subseteq> set init"
  assumes 3: "distinct init"
  assumes 4: "\<And>x. x<length qs \<Longrightarrow> finite (set_pmf (config'' A qs init x))"
   shows "T\<^sub>p_on_rand A init qs
      = (\<Sum>(x,y)\<in>{(x, y). x \<in> set init \<and> y \<in> set init \<and> x < y}. T\<^sub>p_on_rand A (Lxy init {x,y}) (Lxy qs {x,y}))"
proof -
  have " T\<^sub>p_on_rand A init qs = (\<Sum>(x,y)\<in>{(x, y). x \<in> set init \<and> y \<in> set init \<and> x < y}. ALGxy A qs init x y)"
    by(simp only: umformung[OF 1 2 3 4])
  also have "\<dots> = (\<Sum>(x,y)\<in>{(x, y). x \<in> set init \<and> y \<in> set init \<and> x < y}. T\<^sub>p_on_rand A (Lxy init {x,y}) (Lxy qs {x,y}))"
    apply(rule setsum.cong)
      apply(simp)
      using 0[unfolded pairwise_def] 2 3 by auto
  finally show ?thesis .
qed
 
section "List Factoring for OPT"


thm ALG.simps
thm swap_def
(* calculates given a list of swaps, elements x and y and a current state
  how many swaps between x and y there are *)
fun ALG_P :: "nat list \<Rightarrow> 'a  \<Rightarrow> 'a  \<Rightarrow> 'a list \<Rightarrow> nat" where
  "ALG_P [] x y xs = (0::nat)"
| "ALG_P (s#ss) x y xs = (if Suc s < length (swaps ss xs)
                          then (if ((swaps ss xs)!s=x \<and> (swaps ss xs)!(Suc s)=y) \<or> ((swaps ss xs)!s=y \<and> (swaps ss xs)!(Suc s)=x)
                                then 1
                                else 0)
                          else 0) + ALG_P ss x y xs"

(* nat list ersetzen durch (a::ordered) list *)
lemma ALG_P_erwischt_alle:
  assumes dinit: "distinct init" 
  shows
  "\<forall>l\<in> set sws. Suc l < length init \<Longrightarrow> length sws
        = (\<Sum>(x,y)\<in>{(x,y). x \<in> set (init::('a::linorder) list) \<and> y\<in>set init \<and> x<y}. ALG_P sws x y init)"
proof (induct sws)
  case (Cons s ss)
  then have isininit: "Suc s < length init" by auto
  
  let ?expr = "(\<lambda>x y. (if Suc s < length (swaps ss init)
                          then (if ((swaps ss init)!s=x \<and> (swaps ss init)!(Suc s)=y) \<or> ((swaps ss init)!s=y \<and> (swaps ss init)!(Suc s)=x)
                                then 1::nat
                                else 0)
                          else 0))"

  let ?expr2 = "(\<lambda>x y. (if ((swaps ss init)!s=x \<and> (swaps ss init)!(Suc s)=y) \<or> ((swaps ss init)!s=y \<and> (swaps ss init)!(Suc s)=x)
                                then 1
                                else 0))"

  let ?expr3 = "(%x y.  ((swaps ss init)!s=x \<and> (swaps ss init)!(Suc s)=y)
                    \<or> ((swaps ss init)!s=y \<and> (swaps ss init)!(Suc s)=x))"
  let ?co' = "swaps ss init"

  from dinit have dco: "distinct ?co'" by auto

  let ?expr4 = "(\<lambda>z. (if z\<in>{(x,y). ?expr3 x y}
                                then 1
                                else 0))"

  have scoinit: "set ?co' = set init" by auto
  from isininit have isT: "Suc s < length ?co'" by auto
  then have isT2: "Suc s < length init" by auto
  then have isT3: "s < length init" by auto
  then have isT6: "s < length ?co'" by auto
  from isT2 have isT7: "Suc s < length ?co'" by auto
  from isT6 have a: "?co'!s \<in> set ?co'" by (rule nth_mem)
  then have a: "?co'!s \<in> set init" by auto
  from isT7 have "?co'! (Suc s) \<in> set ?co'" by (rule nth_mem)
  then have b: "?co'!(Suc s) \<in> set init" by auto

  have  "{(x,y). x \<in> set init \<and> y\<in>set init \<and> x<y}
                          \<inter> {(x,y). ?expr3 x y}
     = {(x,y). x \<in> set init \<and> y\<in>set init \<and> x<y
                              \<and>  (?co'!s=x \<and> ?co'!(Suc s)=y
                                  \<or> ?co'!s=y \<and> ?co'!(Suc s)=x)}" by auto
  also have "\<dots> = {(x,y). x \<in> set init \<and> y\<in>set init \<and> x<y
                              \<and>  ?co'!s=x \<and> ?co'!(Suc s)=y }
                           \<union>
                  {(x,y). x \<in> set init \<and> y\<in>set init \<and> x<y
                              \<and>   ?co'!s=y \<and> ?co'!(Suc s)=x}" by auto
  also have "\<dots> = {(x,y). x<y \<and> ?co'!s=x \<and> ?co'!(Suc s)=y}
                           \<union>
                  {(x,y). x<y \<and> ?co'!s=y \<and> ?co'!(Suc s)=x}"
              using a b by(auto)
  finally have c1: "{(x,y). x \<in> set init \<and> y\<in>set init \<and> x<y} \<inter> {(x,y). ?expr3 x y}
      = {(x,y). x<y \<and> ?co'!s=x \<and> ?co'!(Suc s)=y}
                           \<union>
                  {(x,y). x<y \<and> ?co'!s=y \<and> ?co'!(Suc s)=x}" . 

  have c2: "card ({(x,y). x<y \<and> ?co'!s=x \<and> ?co'!(Suc s)=y}
                           \<union>
                  {(x,y). x<y \<and> ?co'!s=y \<and> ?co'!(Suc s)=x}) = 1" (is "card (?A \<union> ?B) = 1")
  proof (cases "?co'!s<?co'!(Suc s)")
    case True
    then have a: "?A = { (?co'!s, ?co'!(Suc s)) }"
          and b: "?B = {} " by auto
    have c: "?A \<union> ?B = { (?co'!s, ?co'!(Suc s)) }" apply(simp only: a b) by simp 
    have "card (?A \<union> ?B) = 1" unfolding c by auto
    then show ?thesis .
  next
    case False
    then have a: "?A = {}" by auto
    have b: "?B = { (?co'!(Suc s), ?co'!s) } "
    proof -
     from dco distinct_conv_nth[of "?co'"] 
     have "swaps ss init ! s \<noteq> swaps ss init ! (Suc s)" 
      using isT2 isT3 by simp
     with False show ?thesis by auto
    qed

    have c: "?A \<union> ?B = { (?co'!(Suc s), ?co'!s) }" apply(simp only: a b) by simp 
    have "card (?A \<union> ?B) = 1" unfolding c by auto
    then show ?thesis .
  qed
    
        

  have yeah: "(\<Sum>(x,y)\<in>{(x,y). x \<in> set init \<and> y\<in>set init \<and> x<y}. ?expr x y) = (1::nat)"
  proof -
    have "(\<Sum>(x,y)\<in>{(x,y). x \<in> set init \<and> y\<in>set init \<and> x<y}. ?expr x y)
        = (\<Sum>(x,y)\<in>{(x,y). x \<in> set init \<and> y\<in>set init \<and> x<y}. ?expr2 x y)"
          using isT by auto
    also have "\<dots> = (\<Sum>z\<in>{(x,y). x \<in> set init \<and> y\<in>set init \<and> x<y}. ?expr2 (fst z) (snd z))"
        by(simp add: split_def)
    also have "\<dots> = (\<Sum>z\<in>{(x,y). x \<in> set init \<and> y\<in>set init \<and> x<y}. ?expr4 z)"
        by(simp add: split_def)
    also have "\<dots> = (\<Sum>z\<in>{(x,y). x \<in> set init \<and> y\<in>set init \<and> x<y}
                          \<inter>{(x,y). ?expr3 x y} . 1)"
        apply(rule setsum.inter_restrict[symmetric])
              apply(rule finite_subset[where B="set init \<times> set init"])
                by(auto)
    also have "\<dots> = card ({(x,y). x \<in> set init \<and> y\<in>set init \<and> x<y}
                          \<inter> {(x,y). ?expr3 x y})" by auto
    also have "\<dots> = card ({(x,y). x<y \<and> ?co'!s=x \<and> ?co'!(Suc s)=y}
                           \<union>
                  {(x,y). x<y \<and> ?co'!s=y \<and> ?co'!(Suc s)=x})" by(simp only: c1)
    also have "\<dots> = (1::nat)" using c2 by auto
    finally show ?thesis .
  qed

  have "length (s # ss) = 1 + length ss"
    by auto
  also have "\<dots> = 1 + (\<Sum>(x,y)\<in>{(x,y). x \<in> set init \<and> y\<in>set init \<and> x<y}. ALG_P ss x y init)"
    using Cons by auto
  also have "\<dots> = (\<Sum>(x,y)\<in>{(x,y). x \<in> set init \<and> y\<in>set init \<and> x<y}. ?expr x y)
            + (\<Sum>(x,y)\<in>{(x,y). x \<in> set init \<and> y\<in>set init \<and> x<y}. ALG_P ss x y init)"
    by(simp only: yeah)
  also have "\<dots> = (\<Sum>(x,y)\<in>{(x,y). x \<in> set init \<and> y\<in>set init \<and> x<y}. ?expr x y + ALG_P ss x y init)"
    (is "?A + ?B = ?C") 
    by (simp add: setsum.distrib split_def)  
  also have "\<dots> = (\<Sum>(x,y)\<in>{(x,y). x \<in> set init \<and> y\<in>set init \<and> x<y}. ALG_P (s#ss) x y init)"
    by auto
  finally show ?case . 
qed (simp)




(* thesame with paid exchanges *)
lemma t\<^sub>p_sumofALGALGP: "distinct s \<Longrightarrow> (qs!i)\<in>set s 
  \<Longrightarrow> \<forall>l\<in>set (snd a). Suc l < length s
  \<Longrightarrow> t\<^sub>p s (qs!i) a = (\<Sum>e\<in>set s. ALG e qs i (swaps (snd a) s,()))
      + (\<Sum>(x,y)\<in>{(x::('a::linorder),y). x \<in> set s \<and> y\<in>set s \<and> x<y}. ALG_P (snd a) x y s)"
proof -
  case goal1

  (* paid exchanges *)
  have pe: "length (snd a)
        = (\<Sum>(x,y)\<in>{(x,y). x \<in> set s \<and> y\<in>set s \<and> x<y}. ALG_P (snd a) x y s)"   
    apply(rule ALG_P_erwischt_alle)  
        by(fact)+                                              


  (* access cost *)
  have ac: "index (swaps (snd a) s) (qs ! i) = (\<Sum>e\<in>set s. ALG e qs i (swaps (snd a) s,()))"
  proof -
    have "index (swaps (snd a) s) (qs ! i) 
        = (\<Sum>e\<in>set (swaps (snd a) s). if e < (qs ! i) in (swaps (snd a) s) then 1 else 0)" 
          apply(rule index_sum)
            using goal1 by(simp_all)
    also have "\<dots> = (\<Sum>e\<in>set s. ALG e qs i (swaps (snd a) s,()))" by auto
    finally show ?thesis .
  qed

  show ?case
    unfolding t\<^sub>p_def apply (simp add: split_def)
    unfolding ac pe by (simp add: split_def)
qed


(*
lemma ALG_P_1: "Suc s < length xs \<Longrightarrow> (xs!s=x \<and> xs!(Suc s)=y) \<or> (xs!s=y \<and> xs!(Suc s)=x) \<Longrightarrow>
ALG_P (s#ss) x y xs = 1 + ALG_P ss x y (swap s xs)" by(simp)

lemma ALG_P_0a: "~ Suc s < length xs \<Longrightarrow> ALG_P (s#ss) x y xs = 0 + ALG_P ss x y (swap s xs)" by(auto)
lemma ALG_P_0b: "Suc s < length xs \<Longrightarrow> ~((xs!s=x \<and> xs!(Suc s)=y) \<or> (xs!s=y \<and> xs!(Suc s)=x)) \<Longrightarrow> ALG_P (s#ss) x y xs = 0 + ALG_P ss x y (swap s xs)" by auto

lemma ALG_P_0: "(~ Suc s < length xs) \<or> ~((xs!s=x \<and> xs!(Suc s)=y) \<or> (xs!s=y \<and> xs!(Suc s)=x)) \<Longrightarrow> ALG_P (s#ss) x y xs = 0 + ALG_P ss x y (swap s xs)"
  by(auto)
*)



lemma "Suc ` set sws \<subseteq> {..<length s}
  \<Longrightarrow> (\<Sum>(x,y)\<in>{(x,y). x\<in>set s \<and> y\<in>set s \<and> x<y}. ALG_P sws x y s) = length sws"
sorry

(* given a Strategy Strat to serve request sequence qs on initial list init how many
  swaps between elements x and y occur during the ith step *)
definition "ALG_P' Strat qs init i x y = ALG_P (snd (Strat!i)) x y (steps' init qs Strat i)"

(* if n is in bound, Strat may be too long, that does not matter *)
lemma ALG_P'_rest: "n < length qs \<Longrightarrow> n < length Strat \<Longrightarrow> 
  ALG_P' Strat (take n qs @ [qs ! n]) init n x y =
    ALG_P' (take n Strat @ [Strat ! n]) (take n qs @ [qs ! n]) init n x y"
proof -
  assume qs: "n < length qs"
  assume S: "n < length Strat"

  then have lS: "length (take n Strat) = n" by auto
  have "(take n Strat @ [Strat ! n]) ! n =
      (take n Strat @ (Strat ! n) # []) ! length (take n Strat)" using lS by auto
  also have "\<dots> = Strat ! n" by(rule nth_append_length)
  finally have tt: "(take n Strat @ [Strat ! n]) ! n = Strat ! n" .

  obtain rest where rest: "Strat = (take n Strat @ [Strat ! n] @ rest)" 
        using S apply(auto) using id_take_nth_drop by blast
  thm steps'_rests
  have "steps' init (take n qs @ [qs ! n])
       (take n Strat @ [Strat ! n]) n
      = steps' init (take n qs)
       (take n Strat) n"
       apply(rule steps'_rests[symmetric])
        using S qs by auto
  also have "\<dots> = 
      steps' init (take n qs @ [qs ! n])
       (take n Strat @ ([Strat ! n] @ rest)) n"
       apply(rule steps'_rests)
        using S qs by auto
  finally show ?thesis unfolding ALG_P'_def tt using rest by auto
qed

(* verallgemeinert ALG_P'_rest, sollte mergen! *)
lemma ALG_P'_rest2: "n < length qs \<Longrightarrow> n < length Strat \<Longrightarrow> 
  ALG_P' Strat qs init n x y =
    ALG_P' (Strat@r1) (qs@r2) init n x y"
proof -
  assume qs: "n < length qs"
  assume S: "n < length Strat"

  have tt: "Strat ! n = (Strat @ r1) ! n"
    using S by (simp add: nth_append)

  have "steps' init (take n qs) (take n Strat) n = steps' init ((take n qs) @ drop n qs) ((take n Strat) @ (drop n Strat)) n"
       apply(rule steps'_rests)
        using S qs by auto
  then have A: "steps' init (take n qs) (take n Strat) n = steps' init qs Strat n" by auto
  have "steps' init (take n qs) (take n Strat) n = steps' init ((take n qs) @ ((drop n qs)@r2)) ((take n Strat) @((drop n Strat)@r1)) n"
       apply(rule steps'_rests)
        using S qs by auto
  then have B: "steps' init (take n qs) (take n Strat) n = steps' init (qs@r2) (Strat@r1) n"
    by (metis append_assoc List.append_take_drop_id)
  from A B have C: "steps' init qs Strat n = steps' init (qs@r2) (Strat@r1) n" by auto
  show ?thesis unfolding ALG_P'_def tt using C by auto

qed



(* total number of swaps of elements x and y during execution of Strategy Strat *)
definition ALG_Pxy  where
  "ALG_Pxy Strat qs init x y = (\<Sum>i<length qs. ALG_P' Strat qs init i x y)"

term "(\<Sum>i < k. f k)"
lemma "{..<n}={x. x<n}" by auto
lemma "(\<Sum>i | i < k. f k) = (\<Sum>(i::nat) < k. (f::nat\<Rightarrow>nat) k)"
apply(auto) done

lemma wtf: "(\<Sum>i | i < Suc n. f i) = (\<Sum>i| i < n. f i) + f n"
sorry
thm setsum_lessThan_Suc

lemma wegdamit: "length A < length Strat \<Longrightarrow> b \<notin> {x,y} \<Longrightarrow> ALGxy_det Strat (A @ [b]) init x y
    = ALGxy_det Strat A init x y" 
proof -
  assume bn: "b \<notin> {x,y}"
  have "(A @ [b]) ! (length A) = b" by auto
  assume l: "length A < length Strat"

  term "%i. ALG'_det Strat (A @ [b]) init i y"

  have e: "\<And>i. i<length A \<Longrightarrow> (A @ [b]) ! i = A ! i" by(auto simp: nth_append)
 have "(\<Sum>i | i < length (A @ [b]).
        if (A @ [b]) ! i \<in> {y, x}
        then ALG'_det Strat (A @ [b]) init i y +
             ALG'_det Strat (A @ [b]) init i x
        else 0) = (\<Sum>i | i < Suc (length A).
        if (A @ [b]) ! i \<in> {y, x}
        then ALG'_det Strat (A @ [b]) init i y +
             ALG'_det Strat (A @ [b]) init i x
        else 0)" by auto 
  also have "\<dots> = (\<Sum> i | i < length A.
        if (A @ [b]) ! i \<in> {y, x}
        then ALG'_det Strat (A @ [b]) init i y +
             ALG'_det Strat (A @ [b]) init i x
        else 0) + ( if (A @ [b]) ! (length A) \<in> {y, x}
        then ALG'_det Strat (A @ [b]) init (length A) y +
             ALG'_det Strat (A @ [b]) init (length A) x
        else 0) " by (rule wtf) (* abspalten des letzten glieds *)
        also have "\<dots> = (\<Sum>i | i < length A.
        if (A @ [b]) ! i \<in> {y, x}
        then ALG'_det Strat (A @ [b]) init i y +
             ALG'_det Strat (A @ [b]) init i x
        else 0)" using bn by auto
        also have "\<dots> = (\<Sum>i | i < length A.
          if A ! i \<in> {y, x}
          then ALG'_det Strat A init i y +
              ALG'_det Strat A init i x
              else 0)"
            apply(rule setsum.cong)
              apply(simp)
              using l ALG'_det_append[where qs=A] e by(simp)
     finally show ?thesis unfolding ALGxy_det_def by simp
qed

lemma ALG_P_split: "length qs < length Strat \<Longrightarrow> ALG_Pxy Strat (qs@[q]) init x y = ALG_Pxy Strat qs init x y
            +  ALG_P' Strat (qs@[q]) init (length qs) x y "
unfolding ALG_Pxy_def apply(auto)
  apply(rule setsum.cong)
    apply(simp)
    using ALG_P'_rest2[symmetric, of _ qs Strat "[]" "[q]"] by(simp)
    

lemma swap0in2:  assumes "set l = {x,y}" "x\<noteq>y" "length l = 2" "dist_perm l l"
  shows
    "x < y in (swap 0) l = (~ x < y in l)"
proof (cases "x < y in l")
  case True
  then have a: "index l x < index l y" unfolding before_in_def by simp
  from assms(1) have drin: "x\<in>set l" "y\<in>set l" by auto
  from assms(1,3) have b: "index l y < 2" by simp
  from a b have k: "index l x = 0" "index l y = 1" by auto 
  thm nth_index[OF drin(1)]
  have g: "x = l ! 0" "y = l ! 1"
    using k nth_index assms(1) by force+ 

      have "x < y in swap 0 l
      = (x < y in l \<and> \<not> (x = l ! 0 \<and> y = l ! Suc 0)
            \<or>  x = l ! Suc 0 \<and> y = l ! 0)"
            apply(rule before_in_swap)
              apply(fact assms(4))
              using assms(3) by simp
  also have "\<dots> = (\<not> (x = l ! 0 \<and> y = l ! Suc 0)
            \<or>  x = l ! Suc 0 \<and> y = l ! 0)" using True by simp
  also have "\<dots> = False" using g assms(2) by auto
  finally have "~ x < y in (swap 0) l" by simp
  then show ?thesis using True by auto
next
  case False
  from assms(1,2) have "index l y \<noteq> index l x" by simp
  with False assms(1,2) have a: "index l y < index l x"
    by (metis before_in_def insert_iff linorder_neqE_nat)
  from assms(1) have drin: "x\<in>set l" "y\<in>set l" by auto
  from assms(1,3) have b: "index l x < 2" by simp
  from a b have k: "index l x = 1" "index l y = 0" by auto
  then have g: "x = l ! 1" "y = l ! 0" 
    using k nth_index assms(1) by force+ 
  have "x < y in swap 0 l
      = (x < y in l \<and> \<not> (x = l ! 0 \<and> y = l ! Suc 0)
            \<or>  x = l ! Suc 0 \<and> y = l ! 0)"
            apply(rule before_in_swap)
              apply(fact assms(4))
              using assms(3) by simp
  also have "\<dots> = (x = l ! Suc 0 \<and> y = l ! 0)" using False by simp
  also have "\<dots> = True" using g by auto
  finally have "x < y in (swap 0) l" by simp
  then show ?thesis using False by auto
qed 



lemma before_in_swap2:
 "dist_perm xs ys \<Longrightarrow> Suc n < size xs \<Longrightarrow> x\<noteq>y \<Longrightarrow>
  x < y in (swap n xs) \<longleftrightarrow>
  (~ x < y in xs \<and> (y = xs!n \<and> x = xs!Suc n)
      \<or> x < y in xs \<and> ~(y = xs!Suc n \<and> x = xs!n))"
apply(simp add:before_in_def index_swap_distinct)
by (metis Suc_lessD Suc_lessI index_nth_id less_Suc_eq nth_mem yes)

lemma geil: 
  assumes
   d: "dist_perm s1 s1"  
  and ee: "x\<noteq>y"  
  and f: "set s2 = {x, y}"  
  and g: "length s2 = 2"  
  and h: "dist_perm s2 s2"  
  shows "x < y in s1 = x < y in s2 \<Longrightarrow>
  x < y in swaps acs s1 = x < y in (swap 0 ^^ ALG_P acs x y s1) s2"
proof (induct acs)
  case Nil
  then show ?case by auto
next
  case (Cons s ss)
  from d have dd: "dist_perm (swaps ss s1) (swaps ss s1)" by simp
  from f have ff: "set ((swap 0 ^^ ALG_P ss x y s1) s2) = {x, y}" by (metis foldr_replicate swaps_inv)
  from g have gg: "length ((swap 0 ^^ ALG_P ss x y s1) s2) = 2"  by (metis foldr_replicate swaps_inv)
  from h have hh: "dist_perm ((swap 0 ^^ ALG_P ss x y s1) s2) ((swap 0 ^^ ALG_P ss x y s1) s2)" by (metis foldr_replicate swaps_inv) 
  show ?case (is "?LHS = ?RHS")
  proof (cases "Suc s < length (swaps ss s1) \<and> (((swaps ss s1)!s=x \<and> (swaps ss s1)!(Suc s)=y) \<or> ((swaps ss s1)!s=y \<and> (swaps ss s1)!(Suc s)=x))")
    case True
    from True have 1:" Suc s < length (swaps ss s1)"
          and 2: "(swaps ss s1 ! s = x \<and> swaps ss s1 ! Suc s = y
            \<or>  swaps ss s1 ! s = y \<and> swaps ss s1 ! Suc s = x)" by auto
    from True have "ALG_P (s # ss) x y s1 =  1 + ALG_P ss x y s1" by auto
    then have "?RHS = x < y in (swap 0) ((swap 0 ^^ ALG_P ss x y s1) s2)"
      by auto
    also have "\<dots> = (~ x < y in ((swap 0 ^^ ALG_P ss x y s1) s2))" 
      apply(rule swap0in2)
        by(fact)+
    also have "\<dots> = (~ x < y in swaps ss s1)" 
      using Cons by auto
    also have "\<dots> = x < y in (swap s) (swaps ss s1)"
      using 1  2 before_in_swap
      by (metis Suc_lessD before_id dd lessI no_before_inI) (* bad *)
    also have "\<dots> = ?LHS" by auto
    finally show ?thesis by simp
  next
    case False
    note F=this
    then have "ALG_P (s # ss) x y s1 =  ALG_P ss x y s1" by auto
    then have "?RHS = x < y in ((swap 0 ^^ ALG_P ss x y s1) s2)"
      by auto
    also have "\<dots> = x < y in swaps ss s1" 
      using Cons by auto
    also have "\<dots> = x < y in (swap s) (swaps ss s1)"
    proof (cases "Suc s < length (swaps ss s1)")
      case True
      with F have g: "swaps ss s1 ! s \<noteq> x \<or>
         swaps ss s1 ! Suc s \<noteq> y" and
        h: "swaps ss s1 ! s \<noteq> y \<or>
         swaps ss s1 ! Suc s \<noteq> x" by auto 
         show ?thesis 
          unfolding before_in_swap[OF dd True, of x y] apply(simp)
            using g h by auto
    next
      case False
      then show ?thesis unfolding swap_def by(simp)
    qed
    also have "\<dots> = ?LHS" by auto
    finally show ?thesis by simp
  qed
qed 
 

(*
lemma geil1: "x < y in s1 = x < y in s2 \<Longrightarrow>
  x < y in swaps acs s1 = x < y in (swap 0 ^^ ALG_P acs x y s1) s2"
proof -
    assume mono: "(x < y in s1) = (x < y in s2)"
    
    from mono show "(x < y in (swaps acs s1))
        = (x < y in (swap 0 ^^ (ALG_P acs x y s1)) s2)"
    proof(induct acs arbitrary: s1 s2)
      case (Cons A AS)
      have dists1: "distinct s1" sorry
      let ?s1'="(swaps AS s1)"
      show ?case
        proof (cases "Suc A < length s1")
          case False
          then have a: "x < y in swaps (A # AS) s1 =
                    x < y in swaps AS s1" by auto
          from False have b: "ALG_P (A # AS) x y s1 
              = ALG_P AS x y s1" by auto
          from a b Cons(1)[OF Cons(2)] show ?thesis by auto
        next
          case True
          note lengthok=this
          then have lengthok': "Suc A < length ?s1'" by auto
          from True dists1 have dp: "dist_perm ?s1' s1" by auto
          show ?thesis
          proof (cases "(?s1'!A=x \<and> ?s1'!(Suc A)=y) \<or> (?s1'!A=y \<and> ?s1'!(Suc A)=x)")
            case False
            then have a: "x < y in swaps (A # AS) s1 =
                      x < y in swaps AS s1"
                using before_in_swap[OF dp lengthok'] apply(simp)
                by (blast)
            from lengthok' False have b: "ALG_P (A # AS) x y s1 
              = ALG_P AS x y s1"
                by(simp add: ALG_P.simps )
            from a b Cons(1)[OF Cons(2)] show ?thesis by auto
           next
           case True
            have xny: "x\<noteq>y" sorry
            have to: "x \<in> set s1" sorry
            then have tox2: "x \<in> set (swaps AS s1)" by auto
            have toy: "y \<in> set s1" sorry
            then have toy2: "y \<in> set (swaps AS s1)" by auto
            thm not_before_in
            from True have a: "x < y in swaps (A # AS) s1 =
                      (~(x < y in swaps AS s1))"
                apply(simp add:  before_in_swap[OF dp lengthok'])
                unfolding not_before_in[OF tox2 toy2]
                using xny apply(simp)
                  using xny not_before_in using dp lengthok' by auto
                
            from lengthok' True have b: "ALG_P (A # AS) x y s1 
              = 1 + ALG_P AS x y s1"
                by(simp add: ALG_P.simps )

            have "(x < y in (swap 0 ^^ ALG_P (A # AS) x y s1) s2)
              = x < y in (swap (0::nat) ((swap 0 ^^ ALG_P AS x y s1) s2))"
                unfolding b by(simp)
            also have "\<dots> = (~ x < y in ((swap 0 ^^ ALG_P AS x y s1) s2))"
                sorry (* involves proving that s2 is of length 2 and contains x,y,
                        and swap doesnt alter these facts *)
            finally have c: "(x < y in (swap 0 ^^ ALG_P (A # AS) x y s1) s2)
                  = (~ x < y in ((swap 0 ^^ ALG_P AS x y s1) s2))" .

            from a b c Cons(1)[OF Cons(2)] show ?thesis by auto
           qed
        qed
    qed (simp add: swap_def)
qed
*)


lemma steps_steps':
  "length qs = length as \<Longrightarrow> steps s qs as = steps' s qs as (length as)"
by (induct qs as arbitrary: s rule: list_induct2) (auto)




term "swaps"
lemma T1_7': "T\<^sub>p init qs Strat = T\<^sub>p_opt init qs \<Longrightarrow> length Strat = length qs
      \<Longrightarrow> n\<le>length qs \<Longrightarrow>  
      x\<noteq>(y::('a::linorder)) \<Longrightarrow>
      x\<in> set init \<Longrightarrow> y \<in> set init \<Longrightarrow> distinct init \<Longrightarrow>
      set qs \<subseteq> set init \<Longrightarrow>
      (\<exists>Strat2 sws. 
        (*T\<^sub>p_opt (Lxy init {x,y}) (Lxy (take n qs) {x,y}) \<le> T\<^sub>p (Lxy init {x,y}) (Lxy (take n qs) {x,y}) Strat2
          \<and>*)  length Strat2 = length (Lxy (take n qs) {x,y})
          \<and>     (x < y in (steps' init (take n qs) (take n Strat) n))
              = (x < y in (swaps sws (steps' (Lxy init {x,y}) (Lxy (take n qs) {x,y}) Strat2 (length Strat2))))
          \<and> T\<^sub>p (Lxy init {x,y}) (Lxy (take n qs) {x,y}) Strat2 + length sws =            
          ALGxy_det Strat (take n qs) init x y + ALG_Pxy Strat (take n qs) init x y)"
proof(induct n)
  case (Suc n)
  from Suc(3,4) have ns: "n < length qs" by simp
  then have n: "n \<le> length qs" by simp
  from Suc(1)[OF Suc(2) Suc(3) n Suc(5) Suc(6) Suc(7) Suc(8) Suc(9) ] obtain Strat2 sws where 
  (*S2: "T\<^sub>p_opt (Lxy init {x,y}) (Lxy (take n qs) {x, y})
     \<le> T\<^sub>p (Lxy init {x,y}) (Lxy (take n qs) {x, y}) Strat2"
     and *) len: "length Strat2 = length (Lxy (take n qs) {x, y})"
     and iff:
      "x < y in steps' init (take n qs) (take n Strat) n
         =
       x < y in swaps sws (steps' (Lxy init {x,y}) (Lxy (take n qs) {x, y}) Strat2 (length Strat2))"   

     and T_Strat2: "T\<^sub>p (Lxy init {x,y}) (Lxy (take n qs) {x, y}) Strat2 + length sws =
     ALGxy_det Strat (take n qs) init x y +
     ALG_Pxy Strat (take n qs) init x y "  by (auto) 
     
  from Suc(3-4) have nStrat: "n < length Strat" by auto 
  from take_Suc_conv_app_nth[OF this] have tak2: "take (Suc n) Strat = take n Strat @ [Strat ! n]" by auto


  from take_Suc_conv_app_nth[OF ns] have tak: "take (Suc n) qs = take n qs @ [qs ! n]" by auto

  thm steps'_append
  have aS: "length (take n Strat) = n" using Suc(3,4) by auto
  have aQ: "length (take n qs) = n" using Suc(4) by auto
  from aS aQ have qQS: "length (take n qs) = length (take n Strat)" by auto
  thm  steps'_append[OF qQS aQ]


  have xyininit: "x\<in> set init" "y : set init" by fact+
  then have xysubs: "{x,y} \<subseteq> set init" by auto
  have dI:  "distinct init" by fact
  have "set qs \<subseteq> set init" by fact
  then have qsnset: "qs ! n \<in> set init" using ns by auto


  from xyininit have ahjer: "set (Lxy init {x, y}) = {x,y}" 
    using xysubs by (simp add: Lxy_set_filter)
  with Suc(5) have ah: "card (set (Lxy init {x, y})) = 2"
    by simp
  have ahjer3: "distinct (Lxy init {x,y})"           
    apply(rule Lxy_distinct) by fact
  from ah have ahjer2: "length (Lxy init {x,y}) = 2"
    using distinct_card[OF ahjer3] by simp

  show ?case
  proof (cases "qs ! n \<in> {x,y}")
    case False
    with tak have nixzutun: "Lxy (take (Suc n) qs) {x,y}  = Lxy (take n qs) {x,y}"
      unfolding Lxy_def by simp
    let ?m="ALG_P' (take n Strat @ [Strat ! n]) (take n qs @ [qs ! n]) init n x y"
    let ?L="replicate ?m 0 @ sws" 

    thm before_in_mtf before_in_swap
 


         {
            fix xs::"('a::linorder) list"
            fix m::nat
            fix q::'a
            assume "q \<notin> {x,y}"
            then have 5: "y \<noteq> q" by auto
            assume 1: "q \<in> set xs"
            assume 2: "distinct xs"
            assume 3: "x \<in> set xs"
            assume 4: "y \<in> set xs"
            have "(x < y in xs) = (x < y in (mtf2 m q xs))"
              by (metis "1" "2" "3" "4" `q \<notin> {x, y}` insertCI not_before_in set_mtf2 swapped_by_mtf2)
          } note f=this


          value "swaps [0,1] [0,1,2::int]"
          (* swaps funktioniert von hinten nach vorne! *) 
          { fix a as l
            have "swaps (a#as) l = swap a (swaps as l)"
              by(auto)
          }




          (* taktik, erstmal das mtf weg bekommen,
            dann induct über snd (Strat!n) *)
          have "(x < y in steps' init (take (Suc n) qs) (take (Suc n) Strat) (Suc n))
            = (x < y in mtf2 (fst (Strat ! n)) (qs ! n)
             (swaps (snd (Strat ! n)) (steps' init (take n qs) (take n Strat) n)))"             
          unfolding tak2 tak apply(simp only: steps'_append[OF qQS aQ] )
          by (simp add: step_def split_def)
          thm before_in_mtf
          also have "\<dots> = (x < y in (swaps (snd (Strat ! n)) (steps' init (take n qs) (take n Strat) n)))"
            apply(rule f[symmetric])
              apply(fact)
              using qsnset steps'_set[OF qQS aS] apply(simp)
              using steps'_distinct[OF qQS aS] dI apply(simp) 
              using steps'_set[OF qQS aS] xyininit by simp_all
          also have "\<dots> =  x < y in (swap 0 ^^ ALG_P (snd (Strat ! n)) x y (steps' init (take n qs) (take n Strat) n))
                                    (swaps sws (steps' (Lxy init {x, y}) (Lxy (take n qs) {x, y}) Strat2 (length Strat2)))"
                 apply(rule geil)
                  apply(rule steps'_dist_perm)
                    apply(fact qQS)
                    apply(fact aS)
                    using dI apply(simp)
                  apply(fact Suc(5))
                  apply(simp)
                    thm steps'_set[where s="Lxy init {x,y}", unfolded ahjer]
                    apply(rule steps'_set[where s="Lxy init {x,y}", unfolded ahjer])
                      using len apply(simp)
                      apply(simp)
                  apply(simp)
                    apply(rule steps'_length[where s="Lxy init {x,y}", unfolded ahjer2])
                      using len apply(simp)
                      apply(simp)
                  apply(simp)
                    apply(rule steps'_distinct2[where s="Lxy init {x,y}"])
                      using len apply(simp)
                      apply(simp)
                      apply(fact)
                  using iff by auto
                                    
          finally have umfa: "x < y in steps' init (take (Suc n) qs) (take (Suc n) Strat) (Suc n) =
  x < y
  in (swap 0 ^^ ALG_P (snd (Strat ! n)) x y (steps' init (take n qs) (take n Strat) n))
      (swaps sws (steps' (Lxy init {x, y}) (Lxy (take n qs) {x, y}) Strat2 (length Strat2)))" .


          thm tak2 tak 
          from Suc(3,4) have lS: "length (take n Strat) = n" by auto
          have "(take n Strat @ [Strat ! n]) ! n =
              (take n Strat @ (Strat ! n) # []) ! length (take n Strat)" using lS by auto
          also have "\<dots> = Strat ! n" by(rule nth_append_length)
          finally have tt: "(take n Strat @ [Strat ! n]) ! n = Strat ! n" .


    show ?thesis apply(rule exI[where x="Strat2"])
      apply(rule exI[where x="?L"])
      unfolding nixzutun
      apply(safe)
        apply(fact)+
        proof -
          case goal1
          
          thm steps'_rests[OF qQS aS, symmetric]

          show ?case 
          unfolding tak2 tak 
          apply(simp add: step_def split_def)
          unfolding ALG_P'_def
          unfolding tt 
            apply(simp only: steps'_rests[OF qQS aS, symmetric])
           using goal1(1) umfa by auto
        next
          case goal2
          then show ?case  
          apply(simp add: step_def split_def)
          unfolding ALG_P'_def
          unfolding tt 
            apply(simp only: steps'_rests[OF qQS aS, symmetric])
            using umfa[symmetric] by auto
        next
          case goal3
          have ns2: "n < length (take n qs @ [qs ! n])"
              using ns by auto


        have er: "length (take n qs) < length Strat" 
          using Suc.prems(2) aQ ns by linarith

          have "T\<^sub>p (Lxy init {x,y}) (Lxy (take n qs) {x, y}) Strat2
      + length (replicate (ALG_P' Strat (take n qs @ [qs ! n]) init n x y) 0 @ sws)
      = ( T\<^sub>p (Lxy init {x,y}) (Lxy (take n qs) {x, y}) Strat2 + length sws)
          + ALG_P' Strat (take n qs @ [qs ! n])  init n x y" by simp

      also have "\<dots> =  ALGxy_det Strat (take n qs) init x y +
                  ALG_Pxy Strat (take n qs) init x y +
                  ALG_P' Strat (take n qs @ [qs ! n]) init n x y"
        unfolding T_Strat2 by simp

      also
        have "\<dots> = ALGxy_det Strat (take (Suc n) qs) init x y
              + ALG_Pxy Strat (take (Suc n) qs) init x y"
          unfolding tak unfolding wegdamit[OF er False] apply(simp) 
          unfolding ALG_P_split[of "take n qs" Strat "qs ! n" init x y, unfolded aQ, OF nStrat]
          by(simp)
          finally show ?case unfolding tak using ALG_P'_rest[OF ns nStrat] by auto 
     qed
  next
    case True
    note qsinxy=this



    then have yeh: "Lxy (take (Suc n) qs) {x, y} = Lxy (take n qs) {x,y} @ [qs!n]"
      unfolding tak Lxy_def by auto

    from True have garar: "(take n qs @ [qs ! n]) ! n \<in> {y, x}"
      using tak[symmetric] by(auto)
    have aer: "\<forall>i<n.
        ((take n qs @ [qs ! n]) ! i \<in> {y, x})
          = (take n qs ! i \<in> {y, x})" using ns by (metis less_SucI nth_take tak)

    thm tak

    (* erst definiere ich die zwischenzeitlichen Configurationen
               ?xs  \<rightarrow> ?xs'  \<rightarrow> ?xs''
        und
        ?ys \<rightarrow> ?ys' \<rightarrow> ?ys'' \<rightarrow> ?ys'''

        und einige Eigenschaften über sie
    *)

    (* what is the mtf action taken by Strat? *)
    let ?Strat_mft =  "fst (Strat ! n)"
    let ?Strat_sws =  "snd (Strat ! n)"
    (* what is the configuration before the step? *)  
    let ?xs = "steps' init (take n qs) (take n Strat) n"
    (* what is the configuration before the mtf *)
    let ?xs' = "(swaps (snd (Strat!n)) ?xs)"
    let ?xs'' = "steps' init (take (Suc n) qs) (take (Suc n) Strat) (Suc n)"
    let ?xs''2 = "mtf2 ?Strat_mft (qs!n) ?xs'"
    (* position of requested element *)
    let ?no_swap_occurs = "(x < y in ?xs') = (x < y in ?xs''2)"

    let ?mtf="(if ?no_swap_occurs then 0 else 1::nat)"
    let ?m="ALG_P' Strat (take n qs @ [qs ! n]) init n x y"
    let ?L="replicate ?m 0 @ sws"

    let ?newStrat="Strat2@[(?mtf,?L)]"

    thm steps'.simps
    have "?xs'' =  step ?xs (qs!n) (Strat!n)"
          unfolding tak tak2
          apply(rule steps'_append)
            by fact+
    also have "\<dots> = mtf2 (fst (Strat!n)) (qs!n) (swaps (snd (Strat!n)) ?xs)" unfolding step_def
     by (auto simp: split_def)
    finally have A: "?xs'' = mtf2 (fst (Strat!n)) (qs!n) ?xs'" . 

    let ?ys = "(steps' (Lxy init {x, y})
                  (Lxy (take n qs) {x, y}) Strat2 (length Strat2))"
    let ?ys' = "( swaps sws (steps' (Lxy init {x, y})
                  (Lxy (take n qs) {x, y}) Strat2 (length Strat2)))"
    let ?ys'' = " (swap 0 ^^ ALG_P (snd (Strat!n)) x y ?xs) ?ys'"
    let ?ys''' = "(steps' (Lxy init {x, y}) (Lxy (take (Suc n) qs) {x, y}) ?newStrat (length ?newStrat))"

    have gr: "Lxy (take n qs @ [qs ! n]) {x, y} = 
        Lxy (take n qs) {x, y} @ [qs ! n]" unfolding Lxy_def using True by(simp)

    have t: "steps' init (take n qs @ [qs ! n]) Strat n
        = steps' init (take n qs) (take n Strat) n"
          using steps'_rests by (metis aS append_take_drop_id qQS)
    have gge: "swaps (replicate ?m 0) ?ys'
        =  (swap 0 ^^ ALG_P (snd (Strat!n)) x y ?xs) ?ys'"
          unfolding ALG_P'_def t by simp

    have gg: "length ?newStrat = Suc (length Strat2)" by auto
    have "?ys''' =  step ?ys (qs!n) (?mtf,?L)"
          unfolding tak gr unfolding gg
          apply(rule steps'_append)
            using len by auto
    also have "\<dots> = mtf2 ?mtf (qs!n) (swaps ?L ?ys)"
          unfolding step_def by (simp add: split_def)
    also have "\<dots> = mtf2 ?mtf (qs!n) (swaps (replicate ?m 0) ?ys')"
      by (simp)
    also have "\<dots> = mtf2 ?mtf (qs!n) ?ys''"
      using gge by (simp)
    finally have B: "?ys''' = mtf2 ?mtf (qs!n) ?ys''" .
                     

    thm ahjer steps'_set
    have 3: "set ?ys' = {x,y}" using ahjer steps'_set len swaps_inv by metis
    have k: "?ys'' = swaps (replicate (ALG_P (snd (Strat!n)) x y ?xs) 0) ?ys'"
      by (auto)
    have 6: "set ?ys'' = {x,y}" unfolding k using 3 swaps_inv by metis
    have 7: "set ?ys''' = {x,y}" unfolding B using set_mtf2 6 by metis                              
    have 22: "x \<in> set ?ys''" "y \<in> set ?ys''" using 6 by auto
    have 23: "x \<in> set ?ys'''" "y \<in> set ?ys'''" using 7 by auto

    thm geil True iff
    have 26: "(qs!n) \<in> set ?ys''" using 6 True by auto
   
    thm ahjer3 ah
    have "distinct ?ys" apply(rule steps'_distinct2)
      using len ahjer3 by(simp)+
    then have 9: "distinct ?ys'" using swaps_inv by metis              
    then have 27: "distinct ?ys''" unfolding k  using swaps_inv by metis

    from 3 Suc(5) have "card (set ?ys') = 2" by auto
    then have 4: "length ?ys' = 2" using distinct_card[OF 9] by simp
    have "length ?ys'' = 2" unfolding k using 4 swaps_inv by metis
    have 5: "dist_perm ?ys' ?ys'" using 9 by auto




    have sxs: "set ?xs = set init" apply(rule steps'_set) by fact+
    have sxs': "set ?xs' = set ?xs" using swaps_inv by metis
    have sxs'': "set ?xs'' = set ?xs'" unfolding A using set_mtf2 by metis
    have 24: "x \<in> set ?xs'" "y\<in>set ?xs'" "(qs!n) \<in> set ?xs'" 
        using xysubs True sxs sxs' by auto
    have 28: "x \<in> set ?xs''" "y\<in>set ?xs''" "(qs!n) \<in> set ?xs''"  
        using xysubs True sxs sxs' sxs'' by auto

    have 0: "dist_perm init init" using dI by auto
    have 1: "dist_perm ?xs ?xs" apply(rule steps'_dist_perm)
      by fact+
    then have 25: "distinct ?xs'" using swaps_inv by metis


    (* aus der Induktionsvorraussetzung (iff) weiß ich bereits
        dass die Ordnung erhalten wird bis zum nten Schritt,
        mit Theorem geil kann ich auch die paid exchanges abarbeiten ...*)

    from geil[OF 1 Suc(5) 3 4 5, OF iff, where acs="snd (Strat ! n)"]
      have aaa: "x < y in ?xs'  = x < y in ?ys''" .

    (* ... was nun noch fehlt ist, dass die moveToFront anweisungen von Strat
        und Strat2 sich in gleicher Art auf die Ordnung von x und y auswirken
    *)

    have t: "?mtf = (if (x<y in ?xs') = (x<y in ?xs'') then 0 else 1)"
      by (simp add: A)


    have central: "x < y in ?xs'' = x < y  in ?ys'''"
            proof (cases "(x<y in ?xs') = (x<y in ?xs'')")
              case True
              then have "?mtf = 0" using t by auto
              with B have "?ys''' = ?ys''" by auto
              with aaa True show ?thesis by auto
            next
              case False
              then have k: "?mtf = 1" using t by auto
              from False have i: "(x<y in ?xs') = (~x<y in ?xs'')" by auto

              have gn: "\<And>a b. a\<in>{x,y} \<Longrightarrow> b\<in>{x,y} \<Longrightarrow> set ?ys'' = {x,y} \<Longrightarrow>
                  a\<noteq>b \<Longrightarrow> distinct ?ys'' \<Longrightarrow>
                  a<b in ?ys'' \<Longrightarrow> ~a<b in mtf2 1 b ?ys''"
              proof -
                case goal1
                from goal1 have f: "set ?ys'' = {a,b}" by auto
                with goal1 have i: "card (set ?ys'') = 2" by auto
                from goal1(5) have "dist_perm ?ys'' ?ys''" by auto 
                from i distinct_card goal1(5) have g: "length ?ys'' = 2" by metis
                with goal1(6) have d: "index ?ys'' b = 1"
                    using before_in_index2 f goal1(4) by fastforce
                from goal1(2,3) have e: "b \<in> set ?ys''" by auto

                from d e have p: "mtf2 1 b ?ys'' =
                      swap 0 ?ys''" unfolding mtf2_def by auto
                have q: "a < b in swap 0 ?ys'' = (\<not> a < b in ?ys'')"
                  apply(rule swap0in2)
                    by(fact)+
                thm swap0in2
                from goal1(6) p q show ?case by metis
              qed

              show ?thesis
              proof (cases "x<y in ?xs'")
                case True
                with aaa have st: "x < y in ?ys''" by auto
                from True False have "~ x<y in ?xs''" by auto
                with Suc(5) 28 not_before_in A have "y < x in ?xs''" by metis
                with A have "y < x in mtf2 (fst (Strat!n)) (qs!n) ?xs'" by auto
                (*from True swapped_by_mtf2*)
                have itisy: "y = (qs!n)"
                  apply(rule swapped_by_mtf2[where xs= ?xs'])
                    apply(fact)
                    apply(fact)
                    apply(fact 24)
                    apply(fact 24)
                    by(fact)+
                have "~x<y in mtf2 1 y ?ys''" 
                  apply(rule gn)
                    apply(simp)
                    apply(simp)
                    apply(simp add: 6)
                    by(fact)+
                then have ts: "~x<y in ?ys'''"
                    using B itisy k by auto
                have ii: "(x<y in ?ys'') = (~x<y in ?ys''')"
                     using st ts by auto
                from i ii aaa show ?thesis by metis
              next
                case False
                with aaa have st: "~ x < y in ?ys''" by auto
                with Suc(5) 22 not_before_in have st: "y < x in ?ys''" by metis
                from i False have kl: "x<y in ?xs''" by auto
                with A have "x < y in mtf2 (fst (Strat!n)) (qs!n) ?xs'" by auto
                from False Suc(5) 24 not_before_in have "y < x in ?xs'" by metis
                have itisx: "x = (qs!n)"
                  apply(rule swapped_by_mtf2[where xs= ?xs'])
                    apply(fact)
                    apply(fact)
                    apply(fact 24(2))
                    apply(fact 24)
                    by(fact)+
                have "~y<x in mtf2 1 x ?ys''"
                  apply(rule gn)
                    apply(simp)
                    apply(simp)
                    apply(simp add: 6)
                    apply(metis Suc(5))
                    by(fact)+
                then have "~y<x in ?ys'''" 
                    using itisx k B by auto
                with Suc(5) not_before_in 23 have "x<y in ?ys'''" by metis
                with st have ii: "(x<y in ?ys'') = (~x<y in ?ys''')"
                    using  B k by auto
                from i ii aaa show ?thesis by metis
              qed
            qed


    show ?thesis apply(rule exI[where x="?newStrat"])
      apply(rule exI[where x="[]"])
      proof 
        case goal1
        show rightlen: ?case unfolding yeh using len by(simp)
      next
        case goal2
        show ?case
        proof 
            case goal1
            (* hier beweise ich also, dass die ordnung von x und y in der projezierten
                Ausführung (von Strat2) der Ordnung von x und y in der Ausführung
                von Strat entspricht *)
            
            from central show ?case by auto

          next
            case goal2 
            (* nun muss noch bewiesen werden, dass die Kosten sich richtig aufspalten:
                  Kosten für Strat2 + |sws|
                    = blocking kosten von x,y + paid exchange kosten von x,y
            *)

           have j: "ALGxy_det Strat (take (Suc n) qs) init x y =
            ALGxy_det Strat (take n qs) init x y 
                  + (ALG'_det Strat qs init n y + ALG'_det Strat qs init n x)" 
           proof -
            have "ALGxy_det Strat (take (Suc n) qs) init x y =
              (\<Sum>i | i < length (take n qs @ [qs ! n]).
            if (take n qs @ [qs ! n]) ! i \<in> {y, x}
            then ALG'_det Strat (take n qs @ [qs ! n]) init i y
                + ALG'_det Strat (take n qs @ [qs ! n]) init i x
            else 0)" unfolding ALGxy_det_def tak by auto
            also have "\<dots>
             =  (\<Sum>i | i < Suc n.
            if (take n qs @ [qs ! n]) ! i \<in> {y, x}
            then ALG'_det Strat (take n qs @ [qs ! n]) init i y
                + ALG'_det Strat (take n qs @ [qs ! n]) init i x
            else 0)" using ns by simp
           also have "\<dots> = (\<Sum>i | i < n.
            if (take n qs @ [qs ! n]) ! i \<in> {y, x}
            then ALG'_det Strat (take n qs @ [qs ! n]) init i y
                + ALG'_det Strat (take n qs @ [qs ! n]) init i x
            else 0)
              + (if (take n qs @ [qs ! n]) ! n \<in> {y, x}
            then ALG'_det Strat (take n qs @ [qs ! n]) init n y
                + ALG'_det Strat (take n qs @ [qs ! n]) init n x
            else 0)" by (rule wtf) (* TODO: ersetzen! wenn ich gecheckt hab warum thm
                  setsum_lessThan_Suc nicht funktioniert*)
            thm setsum_lessThan_Suc
            also have "\<dots> = (\<Sum>i | i < n.
            if take n qs ! i \<in> {y, x}
            then ALG'_det Strat (take n qs @ [qs ! n]) init i y
                + ALG'_det Strat (take n qs @ [qs ! n]) init i x
            else 0)
              + ALG'_det Strat (take n qs @ [qs ! n]) init n y
                + ALG'_det Strat (take n qs @ [qs ! n]) init n x "
                using aer using garar by simp
            also have "\<dots> = (\<Sum>i | i < n.
            if take n qs ! i \<in> {y, x}
            then ALG'_det Strat (take n qs @ [qs ! n]) init i y
                + ALG'_det Strat (take n qs @ [qs ! n]) init i x
            else 0)
              + ALG'_det Strat qs init n y
                + ALG'_det Strat qs init n x "
                proof -
                  thm ALG'_det_append
                  have "ALG'_det Strat qs init n y
                    = ALG'_det Strat ((take n qs @ [qs ! n]) @ drop (Suc n) qs) init n y"
                    unfolding tak[symmetric] by auto                   
                  also have "\<dots> = ALG'_det Strat (take n qs @ [qs ! n]) init n y "
                      apply(rule ALG'_det_append)
                        using nStrat ns by(auto)
                  finally have 1: "ALG'_det Strat qs init n y = ALG'_det Strat (take n qs @ [qs ! n]) init n y" .
                  have "ALG'_det Strat qs init n x
                    = ALG'_det Strat ((take n qs @ [qs ! n]) @ drop (Suc n) qs) init n x"
                    unfolding tak[symmetric] by auto                   
                  also have "\<dots> = ALG'_det Strat (take n qs @ [qs ! n]) init n x "
                      apply(rule ALG'_det_append)
                        using nStrat ns by(auto)
                  finally have 2: "ALG'_det Strat qs init n x = ALG'_det Strat (take n qs @ [qs ! n]) init n x" .
                  from 1 2 show ?thesis by auto
                qed
            also have "\<dots> = (\<Sum>i | i < n.
            if take n qs ! i \<in> {y, x}
            then ALG'_det Strat (take n qs) init i y
                + ALG'_det Strat (take n qs) init i x
            else 0)
              + ALG'_det Strat qs init n y
                + ALG'_det Strat qs init n x "
                apply(simp)
                apply(rule setsum.cong)
                  apply(simp)
                  apply(simp)
                  using ALG'_det_append[where qs="take n qs"] Suc.prems(2) ns by auto
            also have "\<dots> = (\<Sum>i | i < length(take n qs).
            if take n qs ! i \<in> {y, x}
            then ALG'_det Strat (take n qs) init i y
                + ALG'_det Strat (take n qs) init i x
            else 0)
              + ALG'_det Strat qs init n y
                + ALG'_det Strat qs init n x "
                using aQ by auto
            also have "\<dots> = ALGxy_det Strat (take n qs) init x y 
                  + (ALG'_det Strat qs init n y + ALG'_det Strat qs init n x)"
                  unfolding ALGxy_det_def by(simp)
            finally show ?thesis .
          qed

           thm central aaa
           (* 
              aaa:      x < y in ?xs'  = x < y in ?ys''
              central:  x < y in ?xs'' = x < y  in ?ys''' 
           *) 



            have list: "?ys' = swaps sws (steps (Lxy init {x, y})  (Lxy (take n qs) {x, y}) Strat2)"
              unfolding steps_steps'[OF len[symmetric], of "(Lxy init {x, y})"] by simp

            have j2: "steps' init (take n qs @ [qs ! n]) Strat n
                  = steps' init (take n qs) (take n Strat) n"
            proof -
              have "steps' init (take n qs @ [qs ! n]) Strat n
                = steps' init (take n qs @ [qs ! n]) (take n Strat @ drop n Strat) n"
                  by auto
              also have "\<dots> = steps' init (take n qs) (take n Strat) n"
                 apply(rule steps'_rests[symmetric]) by fact+
              finally show ?thesis .
            qed

            have arghschonwieder: "steps' init (take n qs) (take n Strat) n
                  = steps' init qs Strat n"
            proof -
              have "steps' init qs Strat n
                = steps' init (take n qs @ drop n qs) (take n Strat @ drop n Strat) n"
                  by auto
              also have "\<dots> = steps' init (take n qs) (take n Strat) n"
                 apply(rule steps'_rests[symmetric]) by fact+
              finally show ?thesis by simp
            qed

            have indexe: "((swap 0 ^^ ?m) (swaps sws
                      (steps (Lxy init {x,y}) (Lxy (take n qs) {x, y}) Strat2))) 
              = ?ys''" unfolding ALG_P'_def unfolding list using j2 by auto

            have blocky: "ALG'_det Strat qs init n y
                = (if y < qs ! n in ?xs' then 1 else 0)"
                  unfolding ALG'_det_def ALG.simps by(auto simp: arghschonwieder split_def)
            have blockx: "ALG'_det Strat qs init n x
                = (if x < qs ! n in ?xs' then 1 else 0)"
                  unfolding ALG'_det_def ALG.simps by(auto simp: arghschonwieder split_def)



           have index_is_blocking_cost: "index  ((swap 0 ^^ ?m) (swaps sws
                        (steps (Lxy init {x,y}) (Lxy (take n qs) {x, y}) Strat2))) (qs ! n)
                      = ALG'_det Strat qs init n y + ALG'_det Strat qs init n x"
           proof (cases "x= qs!n")

              case True
              then have "ALG'_det Strat qs init n x = 0"
                unfolding blockx apply(simp) using before_in_irefl by metis
              then have "ALG'_det Strat qs init n y + ALG'_det Strat qs init n x
                  = (if y < x in ?xs' then 1 else 0)" unfolding blocky using True by simp
              also have "\<dots> = (if ~y < x in ?xs' then 0 else 1)" by auto
              also have "\<dots> = (if x < y in ?xs' then 0 else 1)"
                apply(simp) by (meson 24 Suc.prems(4) not_before_in)
              also have "\<dots> = (if x < y in ?ys'' then 0 else 1)" using aaa by simp
              also have "\<dots> = index ?ys'' x"
                  apply(rule before_in_index1)
                    by(fact)+
              finally show ?thesis unfolding indexe using True by auto
            
            next
              case False
              then have q: "y = qs!n" using qsinxy by auto
              then have "ALG'_det Strat qs init n y = 0"
                unfolding blocky apply(simp) using before_in_irefl by metis
              then have "ALG'_det Strat qs init n y + ALG'_det Strat qs init n x
                  = (if x < y in ?xs' then 1 else 0)" unfolding blockx using q by simp 
              also have "\<dots> = (if x < y in ?ys'' then 1 else 0)" using aaa by simp
              thm before_in_index1
              also have "\<dots> = index ?ys'' y"
                  apply(rule before_in_index2)
                    by(fact)+
              finally show ?thesis unfolding indexe using q by auto
            qed
               
      

           have jj: "ALG_Pxy Strat (take (Suc n) qs) init x y =
                ALG_Pxy Strat (take n qs) init x y
                  + ALG_P' Strat (take n qs @ [qs ! n]) init n x y"
           proof -
              have "ALG_Pxy Strat (take (Suc n) qs) init x y
                  = (\<Sum>i<length (take (Suc n) qs). ALG_P' Strat (take (Suc n) qs) init i x y)" 
                  unfolding ALG_Pxy_def by simp
              also have "\<dots> = (\<Sum>i< Suc n. ALG_P' Strat (take (Suc n) qs) init i x y)"
                unfolding tak using ns by simp
              also have "\<dots> = (\<Sum>i<n. ALG_P' Strat (take (Suc n) qs) init i x y)
                  + ALG_P' Strat (take (Suc n) qs) init n x y"
                by simp
              also have "\<dots> = (\<Sum>i<length (take n qs). ALG_P' Strat (take n qs @ [qs ! n]) init i x y)
                  + ALG_P' Strat (take n qs @ [qs ! n]) init n x y"
                    unfolding tak using ns by auto
              also have "\<dots> = (\<Sum>i<length (take n qs). ALG_P' Strat (take n qs) init i x y) 
                  + ALG_P' Strat (take n qs @ [qs ! n]) init n x y" (is "?A + ?B = ?A' + ?B")
              proof -
                have "?A = ?A'"
                apply(rule setsum.cong)
                  apply(simp)
                  proof -
                    case goal1
                    show ?case
                       apply(rule ALG_P'_rest2[symmetric, where ?r1.0="[]", simplified])
                        using goal1 apply(simp)
                        using goal1 nStrat by(simp)
                  qed
                then show ?thesis by auto
              qed                        
              also have "\<dots> = ALG_Pxy Strat (take n qs) init x y
                  + ALG_P' Strat (take n qs @ [qs ! n]) init n x y" 
                    unfolding ALG_Pxy_def by auto
              finally show ?thesis .
            qed

            thm T_append
            have tw: "length (Lxy (take n qs) {x, y}) = length Strat2" 
              using len by auto
            have "T\<^sub>p (Lxy init {x,y}) (Lxy (take (Suc n) qs) {x, y}) ?newStrat + length []
                 = T\<^sub>p (Lxy init {x,y}) (Lxy (take n qs) {x, y}) Strat2
                  + t\<^sub>p (steps (Lxy init {x, y}) (Lxy (take n qs) {x, y}) Strat2) (qs ! n) (?mtf,?L)" 
              unfolding yeh
              by(simp add: T_append[OF tw, of "(Lxy init) {x,y}"]) 
            also have "\<dots> = 
                 T\<^sub>p (Lxy init {x,y}) (Lxy (take n qs) {x, y}) Strat2
                  + length sws
                  + index ((swap 0 ^^ ?m) (swaps sws
                        (steps (Lxy init {x,y}) (Lxy (take n qs) {x, y}) Strat2))) (qs ! n)
                  + ALG_P' Strat (take n qs @ [qs ! n]) init n x y"
              by(simp add: t\<^sub>p_def)
           thm T_Strat2 tak
           (* now use iH *)
           also have "\<dots> = (ALGxy_det Strat (take n qs) init x y 
                  + index ((swap 0 ^^ ?m) (swaps sws
                        (steps (Lxy init {x,y}) (Lxy (take n qs) {x, y}) Strat2))) (qs ! n))
                  + (ALG_Pxy Strat (take n qs) init x y
                  + ALG_P' Strat (take n qs @ [qs ! n]) init n x y)"
                  by (simp only: T_Strat2)
           (* the current cost are equal to the blocking costs: *)   
           also from index_is_blocking_cost have "\<dots> = (ALGxy_det Strat (take n qs) init x y 
                  + ALG'_det Strat qs init n y + ALG'_det Strat qs init n x)
                  + (ALG_Pxy Strat (take n qs) init x y
                  + ALG_P' Strat (take n qs @ [qs ! n]) init n x y)" by auto
           also have "\<dots> = ALGxy_det Strat (take (Suc n) qs) init x y 
                  + (ALG_Pxy Strat (take n qs) init x y
                  + ALG_P' Strat (take n qs @ [qs ! n]) init n x y)" using j by auto
           also have "\<dots> = ALGxy_det Strat (take (Suc n) qs) init x y 
                  + ALG_Pxy Strat (take (Suc n) qs) init x y" using jj by auto
           finally show ?case .
          qed
      qed
  qed
next 
  case 0
  then show ?case apply (simp add: Lxy_def ALGxy_det_def ALG_Pxy_def T_opt_def)
    proof -
      case goal1
      thm Lxy_mono[unfolded Lxy_def]
      show ?case apply(rule Lxy_mono[unfolded Lxy_def, simplified])
        using goal1 by auto
      qed
qed

term "T\<^sub>p_opt"
thm T1_7'
lemma T1_7: "T\<^sub>p init qs Strat = T\<^sub>p_opt init qs 
    \<Longrightarrow> length Strat = length qs
  \<Longrightarrow> x \<noteq> (y::('a::linorder)) \<Longrightarrow>
      x\<in> set init \<Longrightarrow> y \<in> set init \<Longrightarrow> distinct init \<Longrightarrow>
      set qs \<subseteq> set init 

      \<Longrightarrow> T\<^sub>p_opt (Lxy init {x,y}) (Lxy qs {x,y}) \<le> ALGxy_det Strat qs init x y 
                                     + ALG_Pxy Strat qs init x y"
proof -
  case goal1 
  have A:"length qs \<le> length qs" by auto
  have B:"  x \<noteq> y " using goal1 by auto

  from T1_7'[OF goal1(1) goal1(2), of "length qs" x y, OF A B goal1(4) goal1(5) goal1(6) goal1(7)]
    obtain Strat2 sws where 
      len: "length Strat2 = length (Lxy qs {x, y})"
     and "x < y in steps' init qs (take (length qs) Strat)
         (length qs) = x < y in swaps sws (steps' (Lxy init {x,y})
           (Lxy qs {x, y}) Strat2 (length Strat2))"
     and Tp: "T\<^sub>p (Lxy init {x,y}) (Lxy qs {x, y}) Strat2 + length sws
        =  ALGxy_det Strat qs init x y 
         + ALG_Pxy Strat qs init x y" by auto

  thm cInf_lower
  have "T\<^sub>p_opt (Lxy init {x,y}) (Lxy qs {x,y}) \<le> T\<^sub>p (Lxy init {x,y}) (Lxy qs {x, y}) Strat2"
    unfolding T_opt_def
    apply(rule cInf_lower)
      using len by auto
  also have "\<dots> \<le> ALGxy_det Strat qs init x y 
         + ALG_Pxy Strat qs init x y" using Tp by auto
  finally show ?thesis .
qed


(* similar to *)
thm umformung

lemma T_snoc: "length rs = length as
       \<Longrightarrow>  T init (rs@[r]) (as@[a])
        = T init rs as + t\<^sub>p (steps' init rs as (length rs)) r a"
apply(induct rs as arbitrary: init rule: list_induct2) by simp_all

lemma steps'_snoc: "length rs = length as \<Longrightarrow> n = (length as)
       \<Longrightarrow> steps' init (rs@[r]) (as@[a]) (Suc n) = step (steps' init rs as n) r a"
apply(induct rs as arbitrary: init n r a rule: list_induct2)
  by (simp_all) 

lemma "n<length qs \<Longrightarrow> length qs = length Strat 
    \<Longrightarrow> steps' init (take n qs) (take n Strat) n
      = steps' init qs Strat n"  
apply(induct n arbitrary: init)
    apply(simp_all add: take_Suc_conv_app_nth)
    apply(subst steps'_snoc)
      apply(simp_all) sorry

lemma Tp_darstellung: "length qs = length Strat
        \<Longrightarrow> T\<^sub>p init qs Strat =
        (\<Sum>i\<in>{..<length qs}. t\<^sub>p (steps' init qs Strat i) (qs!i) (Strat!i))" 
proof -
  assume a: "length qs = length Strat"
  {fix n
      have " n\<le>length qs
        \<Longrightarrow> T\<^sub>p init (take n qs) (take n Strat) =
        (\<Sum>i\<in>{..<n}. t\<^sub>p (steps' init qs Strat i) (qs!i) (Strat!i))"
  apply(induct n) 
    apply(simp)
    apply(simp add: a take_Suc_conv_app_nth)
      apply(subst T_snoc)
        using a apply(simp)
        apply(simp) sorry
  }
  from a this[of "length qs"] show ?thesis by auto
qed

         
(* Gleichung 1.8 in Borodin *)
lemma umformung_OPT':
  assumes inlist: "set qs \<subseteq> set init"
  assumes dist: "distinct init"
  assumes qsStrat: "length qs = length Strat" 
  shows "T\<^sub>p init qs Strat = 
    (\<Sum>(x,y)\<in>{(x,y::('a::linorder)). x \<in> set init \<and> y\<in>set init \<and> x<y}.
          ALGxy_det Strat qs init x y + ALG_Pxy Strat qs init x y)"
proof -
 (* have config_dist: "\<forall>n. \<forall>xa \<in> set_pmf (config\<^sub>p (I, S) qs init n). distinct (snd xa)"
      using dist config_rand_distinct by metis
*) 

  (* ersten Teil umformen: *)
  thm setsum.commute
  have "(\<Sum>i\<in>{..<length qs}.
    (\<Sum>(x,y)\<in>{(x,y). x \<in> set init \<and> y\<in>set init \<and> x<y}. ALG_P (snd (Strat!i)) x y (steps' init qs Strat i)) )
                = (\<Sum>i\<in>{..<length qs}. 
               (\<Sum>z\<in>{(x,y). x \<in> set init \<and> y\<in>set init \<and> x<y}. ALG_P (snd (Strat!i)) (fst z) (snd z) (steps' init qs Strat i)) )"
          by(auto simp: split_def)
  also have "\<dots>
       = (\<Sum>z\<in>{(x,y). x \<in> set init \<and> y\<in>set init \<and> x<y}.
                (\<Sum>i\<in>{..<length qs}. ALG_P (snd (Strat!i)) (fst z) (snd z) (steps' init qs Strat i)) )" 
          by(rule setsum.commute)
  also have "\<dots> = (\<Sum>(x,y)\<in>{(x,y). x \<in> set init \<and> y\<in>set init \<and> x<y}.
                (\<Sum>i\<in>{..<length qs}. ALG_P (snd (Strat!i)) x y (steps' init qs Strat i)) )"
          by(auto simp: split_def)
  also have "\<dots> = (\<Sum>(x,y)\<in>{(x,y). x \<in> set init \<and> y\<in>set init \<and> x<y}.
                ALG_Pxy Strat qs init x y)"
          unfolding ALG_P'_def ALG_Pxy_def by auto
  finally have paid_part: "(\<Sum>i\<in>{..<length qs}.
    (\<Sum>(x,y)\<in>{(x,y). x \<in> set init \<and> y\<in>set init \<and> x<y}. ALG_P (snd (Strat!i)) x y (steps' init qs Strat i)) )
      = (\<Sum>(x,y)\<in>{(x,y). x \<in> set init \<and> y\<in>set init \<and> x<y}.
                ALG_Pxy Strat qs init x y)" .

  (* zweiten Teil umformen: *)
  
  let ?config = "(%i. swaps (snd (Strat!i)) (steps' init qs Strat i))"

  have "(\<Sum>i\<in>{..<length qs}. 
                (\<Sum>e\<in>set init. ALG e qs i (?config i, ())))
        = (\<Sum>e\<in>set init. 
            (\<Sum>i\<in>{..<length qs}. ALG e qs i (?config i, ())))" 
            by(rule setsum.commute)
  also have "\<dots> = (\<Sum>e\<in>set init.
          (\<Sum>y\<in>set init.
            (\<Sum>i\<in>{i. i<length qs \<and> qs!i=y}. ALG e qs i (?config i,()))))"
            proof (rule setsum.cong)
              case goal2
              have "(\<Sum>i<length qs. ALG x qs i (?config i, ()))
                = setsum (%i. ALG x qs i (?config i, ())) {i. i<length qs}"
                  sorry (*times out:  by (metis lessThan_def) *)
              also have "\<dots> = setsum (%i. ALG x qs i (?config i, ())) 
                        (UNION {y. y\<in> set init} (\<lambda>y. {i. i<length qs \<and> qs ! i = y}))"
                         apply(rule setsum.cong)
                         proof -
                          case goal1                          
                          show ?case apply(auto) using inlist by auto
                         qed simp
              also have "\<dots> = setsum (%t. setsum (%i. ALG x qs i (?config i, ())) {i. i<length qs \<and> qs ! i = t}) {y. y\<in> set init}"
                apply(rule setsum.UNION_disjoint)
                  apply(simp_all) by force
              also have "\<dots> = (\<Sum>y\<in>set init. \<Sum>i | i < length qs \<and> qs ! i = y.
                       ALG x qs i (?config i, ()))" by auto                  
             finally show ?case .
            qed (simp)
   also have "\<dots> = (\<Sum>(x,y)\<in> (set init \<times> set init).
            (\<Sum>i\<in>{i. i<length qs \<and> qs!i=y}. ALG x qs i (?config i, ())))"
       by (rule setsum.cartesian_product)
   also have "\<dots> = (\<Sum>(x,y)\<in> {(x,y). x\<in>set init \<and> y\<in> set init}.
            (\<Sum>i\<in>{i. i<length qs \<and> qs!i=y}. ALG x qs i (?config i, ())))"
            by simp
            thm ALG'_refl
   also have E4: "\<dots> = (\<Sum>(x,y)\<in>{(x,y). x\<in>set init \<and> y\<in> set init \<and> x\<noteq>y}.
            (\<Sum>i\<in>{i. i<length qs \<and> qs!i=y}. ALG x qs i (?config i, ())))" (is "(\<Sum>(x,y)\<in> ?L. ?f x y) = (\<Sum>(x,y)\<in> ?R. ?f x y)")
           proof -
        case goal1
        let ?M = "{(x,y). x\<in>set init \<and> y\<in> set init \<and> x=y}"
        have A: "?L = ?R \<union> ?M" by auto
        have B: "{} = ?R \<inter> ?M" by auto
        thm ALG'_refl
        have "(\<Sum>(x,y)\<in> ?L. ?f x y) = (\<Sum>(x,y)\<in> ?R \<union> ?M. ?f x y)"
          by(simp only: A)
        also have "\<dots> = (\<Sum>(x,y)\<in> ?R. ?f x y) + (\<Sum>(x,y)\<in> ?M. ?f x y)"
            apply(rule setsum.union_disjoint)
              apply(rule finite_subset[where B="set init \<times> set init"])
                apply(auto)
              apply(rule finite_subset[where B="set init \<times> set init"])
                by(auto)
        also have "(\<Sum>(x,y)\<in> ?M. ?f x y) = 0"
          apply(rule setsum.neutral)
            by (auto simp add: split_def before_in_def) 
        finally show ?case by simp
      qed

   also have "\<dots> = (\<Sum>(x,y)\<in>{(x,y). x \<in> set init \<and> y\<in>set init \<and> x<y}.
            (\<Sum>i\<in>{i. i<length qs \<and> qs!i=y}. ALG x qs i (?config i, ()))
           + (\<Sum>i\<in>{i. i<length qs \<and> qs!i=x}. ALG y qs i (?config i, ())) )"
            (is "(\<Sum>(x,y)\<in> ?L. ?f x y) = (\<Sum>(x,y)\<in> ?R. ?f x y +  ?f y x)")
              proof -
              case goal1
                let ?R' = "{(x,y). x \<in> set init \<and> y\<in>set init \<and> y<x}"
                have A: "?L = ?R \<union> ?R'" by auto
                have "{} = ?R \<inter> ?R'" by auto
                have C: "?R' = (%(x,y). (y, x)) ` ?R" by auto

                have D: "(\<Sum>(x,y)\<in> ?R'. ?f x y) = (\<Sum>(x,y)\<in> ?R. ?f y x)"
                proof -
                  case goal1
                  have "(\<Sum>(x,y)\<in> ?R'. ?f x y) = (\<Sum>(x,y)\<in> (%(x,y). (y, x)) ` ?R. ?f x y)"
                      by(simp only: C)
                  also have "(\<Sum>z\<in> (%(x,y). (y, x)) ` ?R. (%(x,y). ?f x y) z) = (\<Sum>z\<in>?R. ((%(x,y). ?f x y) \<circ> (%(x,y). (y, x))) z)"
                    apply(rule setsum.reindex)
                      by(fact swap_inj_on)
                  also have "\<dots> = (\<Sum>z\<in>?R. (%(x,y). ?f y x) z)"
                    apply(rule setsum.cong)
                      by(auto)
                  finally show ?thesis .                  
              qed

                thm setsum.union_disjoint
                have "(\<Sum>(x,y)\<in> ?L. ?f x y) = (\<Sum>(x,y)\<in> ?R \<union> ?R'. ?f x y)"
                  by(simp only: A) 
                also have "\<dots> = (\<Sum>(x,y)\<in> ?R. ?f x y) + (\<Sum>(x,y)\<in> ?R'. ?f x y)"
                  apply(rule setsum.union_disjoint) 
                    apply(rule finite_subset[where B="set init \<times> set init"])
                      apply(auto)
                    apply(rule finite_subset[where B="set init \<times> set init"])
                      by(auto)
                also have "\<dots> = (\<Sum>(x,y)\<in> ?R. ?f x y) + (\<Sum>(x,y)\<in> ?R. ?f y x)"
                    by(simp only: D)                  
                also have "\<dots> = (\<Sum>(x,y)\<in> ?R. ?f x y + ?f y x)"
                  by(simp add: split_def setsum.distrib[symmetric])
              finally show ?thesis .
            qed
                
   also have E5: "\<dots> = (\<Sum>(x,y)\<in>{(x,y). x \<in> set init \<and> y\<in>set init \<and> x<y}.
            (\<Sum>i\<in>{i. i<length qs \<and> (qs!i=y \<or> qs!i=x)}. ALG y qs i (?config i, ()) + ALG x qs i (?config i, ())))"
    apply(rule setsum.cong)
      apply(simp)
      proof -
        case goal1
        then obtain a b where x: "x=(a,b)" and a: "a \<in> set init" "b \<in> set init" "a < b" by auto
        then have "a\<noteq>b" by simp
        then have disj: "{i. i < length qs \<and> qs ! i = b} \<inter> {i. i < length qs \<and> qs ! i = a} = {}" by auto
        have unio: "{i. i < length qs \<and> (qs ! i = b \<or> qs ! i = a)}
            = {i. i < length qs \<and> qs ! i = b} \<union> {i. i < length qs \<and> qs ! i = a}" by auto
        thm setsum_Un
       have "(\<Sum>i\<in>{i. i < length qs \<and> qs ! i = b} \<union>
          {i. i < length qs \<and> qs ! i = a}. ALG b qs i (?config i, ()) +
               ALG a qs i (?config i, ()))
               = (\<Sum>i\<in>{i. i < length qs \<and> qs ! i = b}. ALG b qs i (?config i, ()) +
               ALG a qs i (?config i, ())) + (\<Sum>i\<in>
          {i. i < length qs \<and> qs ! i = a}. ALG b qs i (?config i, ()) +
               ALG a qs i (?config i, ())) - (\<Sum>i\<in>{i. i < length qs \<and> qs ! i = b} \<inter>
          {i. i < length qs \<and> qs ! i = a}. ALG b qs i (?config i, ()) +
               ALG a qs i (?config i, ())) "
               (* apply(rule setsum_Un)
                by(auto) strange *) sorry
        also have "\<dots> = (\<Sum>i\<in>{i. i < length qs \<and> qs ! i = b}. ALG b qs i (?config i, ()) +
               ALG a qs i (?config i, ())) + (\<Sum>i\<in>
          {i. i < length qs \<and> qs ! i = a}. ALG b qs i (?config i, ()) +
               ALG a qs i (?config i, ()))" using disj by auto
        also have "\<dots> = (\<Sum>i\<in>{i. i < length qs \<and> qs ! i = b}. ALG a qs i (?config i, ()))
         + (\<Sum>i\<in>{i. i < length qs \<and> qs ! i = a}. ALG b qs i (?config i, ()))"
          by (auto simp: split_def before_in_def)
        finally 
            show ?case unfolding x apply(simp add: split_def)
          unfolding unio by simp
     qed    
     also have E6: "\<dots> = (\<Sum>(x,y)\<in>{(x,y). x \<in> set init \<and> y\<in>set init \<and> x<y}.
                  ALGxy_det Strat qs init x y)"
           apply(rule setsum.cong)
           unfolding ALGxy_det_alternativ unfolding ALG'_det_def by auto
     finally have blockingpart: "(\<Sum>i<length qs. 
                         \<Sum>e\<in>set init.
                              ALG e qs i (?config i, ()))
                 = (\<Sum>(x,y)\<in>{(x,y). x \<in> set init \<and> y\<in>set init \<and> x<y}. 
                         ALGxy_det Strat qs init x y) " .
  thm setsum.cong
  from Tp_darstellung[OF qsStrat] have E0: "T\<^sub>p init qs Strat =
        (\<Sum>i\<in>{..<length qs}. t\<^sub>p (steps' init qs Strat i) (qs!i) (Strat!i))"
          by auto  (*
  also have "\<dots> = (\<Sum>i\<in>{..<length qs}. 
              index (swaps (snd (Strat!i)) (steps' init qs Strat i)) (qs ! i)
                +  length (snd (Strat!i)))"
                unfolding t\<^sub>p_def by(auto simp: split_def) *)
  also have "\<dots> = (\<Sum>i\<in>{..<length qs}. 
                (\<Sum>e\<in>set (steps' init qs Strat i). ALG e qs i (swaps (snd (Strat!i)) (steps' init qs Strat i),()))
+ (\<Sum>(x,y)\<in>{(x,(y::('a::linorder))). x \<in> set (steps' init qs Strat i) \<and> y\<in>set (steps' init qs Strat i) \<and> x<y}. ALG_P (snd (Strat!i)) x y (steps' init qs Strat i)) )"
            apply(rule setsum.cong)
              apply(simp)
              apply (rule t\<^sub>p_sumofALGALGP)
                using dist steps'_distinct2 sorry
  thm t\<^sub>p_sumofALGALGP
  also have "\<dots> = (\<Sum>i\<in>{..<length qs}. 
                (\<Sum>e\<in>set init. ALG e qs i (swaps (snd (Strat!i)) (steps' init qs Strat i),()))
+ (\<Sum>(x,y)\<in>{(x,y). x \<in> set init \<and> y\<in>set init \<and> x<y}. ALG_P (snd (Strat!i)) x y (steps' init qs Strat i)) )"
                apply(rule setsum.cong)
                  apply(simp)
                  proof -
                    case goal1
                    have "set (steps' init qs Strat x) = set init" sorry
                    then show ?case by simp
                  qed 
  also have "\<dots> = (\<Sum>i\<in>{..<length qs}. 
                (\<Sum>e\<in>set init. ALG e qs i (swaps (snd (Strat!i)) (steps' init qs Strat i), ())))
               + (\<Sum>i\<in>{..<length qs}. 
               (\<Sum>(x,y)\<in>{(x,y). x \<in> set init \<and> y\<in>set init \<and> x<y}. ALG_P (snd (Strat!i)) x y (steps' init qs Strat i)) )"
    by (simp add: setsum.distrib split_def) 
  thm blockingpart
  also have "\<dots> = (\<Sum>(x,y)\<in>{(x,y). x \<in> set init \<and> y\<in>set init \<and> x<y}. 
                         ALGxy_det Strat qs init x y)
               + (\<Sum>i\<in>{..<length qs}. 
               (\<Sum>(x,y)\<in>{(x,y). x \<in> set init \<and> y\<in>set init \<and> x<y}. ALG_P (snd (Strat!i)) x y (steps' init qs Strat i)) )"
                by(simp only: blockingpart)
  thm paid_part
  also have "\<dots> = (\<Sum>(x,y)\<in>{(x,y). x \<in> set init \<and> y\<in>set init \<and> x<y}. 
                         ALGxy_det Strat qs init x y)
               + (\<Sum>(x,y)\<in>{(x,y). x \<in> set init \<and> y\<in>set init \<and> x<y}.
                ALG_Pxy Strat qs init x y)"
                by(simp only: paid_part)
  also have "\<dots> = (\<Sum>(x,y)\<in>{(x,y). x \<in> set init \<and> y\<in>set init \<and> x<y}. 
                         ALGxy_det Strat qs init x y
               +   ALG_Pxy Strat qs init x y)"
    by (simp add: setsum.distrib split_def) 
  finally show ?thesis by auto
qed




lemma nn_contains_Inf:
  fixes S :: "nat set"
  assumes nn: "S \<noteq> {}"
  shows "Inf S \<in> S"
using assms Inf_nat_def LeastI by force



(* Gleichung 1.8 in Borodin *)
lemma umformung_OPT:
  assumes inlist: "set qs \<subseteq> set init"
  assumes dist: "distinct init" 
  assumes a: "T\<^sub>p_opt init qs = T\<^sub>p init qs Strat"
  assumes b: " length qs = length Strat"
  shows "T\<^sub>p_opt init qs = 
    (\<Sum>(x,y)\<in>{(x,y::('a::linorder)). x \<in> set init \<and> y\<in>set init \<and> x<y}.
          ALGxy_det Strat qs init x y + ALG_Pxy Strat qs init x y)"
proof -
    have "T\<^sub>p_opt init qs = T\<^sub>p init qs Strat" by(fact a)
    also have "\<dots> =
    (\<Sum>(x,y)\<in>{(x,y::('a::linorder)). x \<in> set init \<and> y\<in>set init \<and> x<y}.
          ALGxy_det Strat qs init x y + ALG_Pxy Strat qs init x y)"
          apply(rule umformung_OPT')
            apply(fact)+  done
    finally show ?thesis .
qed


corollary OPT_zerlegen: 
  assumes
        dist: "distinct init"
    and setqsinit: "set qs \<subseteq> set init"
  shows "(\<Sum>(x,y)\<in>{(x,y::('a::linorder)). x \<in> set init \<and> y\<in>set init \<and> x<y}. (T\<^sub>p_opt (Lxy init {x,y}) (Lxy qs {x,y})))
        \<le> T\<^sub>p_opt init qs"
proof -

    have "T\<^sub>p_opt init qs \<in> {T\<^sub>p init qs as |as. length as = length qs}"
    unfolding T_opt_def 
      apply(rule nn_contains_Inf)
      apply(auto) by (rule Ex_list_of_length)

    then obtain Strat where a: "T\<^sub>p init qs Strat = T\<^sub>p_opt init qs"
                       and b: "length Strat = length qs"
              unfolding T_opt_def by auto

  thm setsum_mono 
  have "(\<Sum>(x,y)\<in>{(x,y). x \<in> set init \<and> y\<in>set init \<and> x<y}.
       T\<^sub>p_opt (Lxy init {x,y}) (Lxy qs {x, y})) \<le> (\<Sum>(x,y)\<in>{(x,y). x \<in> set init \<and> y\<in>set init \<and> x<y}.
          ALGxy_det Strat qs init x y + ALG_Pxy Strat qs init x y)"
     apply (rule setsum_mono)
     apply(auto)
     proof -
       case goal1
       then have "a\<noteq>b" by auto 
       show ?case apply(rule T1_7[OF a b]) by(fact)+
     qed
  also from umformung_OPT[OF setqsinit dist] a b have "\<dots> = T\<^sub>p init qs Strat" by auto
  also from a have "\<dots> = T\<^sub>p_opt init qs" by simp
  finally show ?thesis .
qed


section "Factoring Lemma"


(*<*)


(* factoring lemma 
lemma factoringlemma:
    fixes A
          and c::real
      assumes c: "c \<ge> 1"
      (* A has pairwise property *)
      and pw: "pairwise A"
      (* A is c-competitive on list of length 2 *) 
      and on2: "\<forall>qs init. \<forall>(x,y)\<in>{(x,y). x \<in> set init \<and> y\<in>set init \<and> x<y}. T\<^sub>p_on A (Lxy qs {x,y}) (Lxy init {x,y}) \<le> c * (T\<^sub>p_opt (Lxy init {x,y}) (Lxy qs {x,y}))" 
      (* then A is c-competitive on arbitrary list lengths *)
      shows "compet\<^sub>p A c UNIV"
proof -
  {
  fix init qs
  thm setsum_mono
  have "T\<^sub>p_on A qs init =
(\<Sum>(x,y)\<in>{(x, y) . x \<in> set init \<and> y \<in> set init \<and> x < y}.
       T\<^sub>p_on A (Lxy qs {x, y}) (Lxy init {x,y}))"
       using umf_pair[OF pw, of qs init] by simp 
       (* 1.4 *)
  also have "\<dots> \<le> (\<Sum>(x,y)\<in>{(x,y). x \<in> set init \<and> y\<in>set init \<and> x<y}. c * (T\<^sub>p_opt (Lxy init {x,y}) (Lxy qs {x,y})))"
        apply(rule setsum_mono)
        using on2 by(simp add: split_def)
  also have "\<dots> = c * (\<Sum>(x,y)\<in>{(x,y). x \<in> set init \<and> y\<in>set init \<and> x<y}. T\<^sub>p_opt (Lxy init {x,y}) (Lxy qs {x,y}))"
        by(simp add: split_def setsum_right_distrib[symmetric])
  also have "\<dots> \<le> c * T\<^sub>p_opt init qs"
    proof -
      have "(\<Sum>(x, y)\<in>{(x, y) . x \<in> set init \<and>
              y \<in> set init \<and> x < y}. T\<^sub>p_opt (Lxy init {x,y}) (Lxy qs {x, y}))
              \<le>  T\<^sub>p_opt init qs"
              using OPT_zerlegen sorry (* by auto assumptions over init and qs needed *)    
      then have "real (\<Sum>(x, y)\<in>{(x, y) . x \<in> set init \<and>
              y \<in> set init \<and> x < y}. T\<^sub>p_opt (Lxy init {x,y}) (Lxy qs {x, y}))
              \<le>  real (T\<^sub>p_opt init qs)"
              by blast
      with c show ?thesis by auto
    qed
  finally have "T\<^sub>p_on A qs init \<le> c * real (T\<^sub>p_opt init qs)" .
  } 
  then show ?thesis unfolding compet_def
    by auto
qed *)



lemma cardofpairs: "S \<noteq> [] \<Longrightarrow> sorted S \<Longrightarrow> distinct S \<Longrightarrow> card {(x,y). x \<in> set S \<and> y\<in>set S \<and> x<y} = ((length S)*(length S-1)) / 2"
proof (induct S rule: list_nonempty_induct)
  case (cons s ss)
  then have "sorted ss" "distinct ss" using sorted_Cons by auto
  from cons(2)[OF this(1) this(2)] have iH: "card {(x, y) . x \<in> set ss \<and> y \<in> set ss \<and> x < y}
    = (length ss * (length ss-1)) / 2"
    by auto

  from cons have sss: "s \<notin> set ss" by auto

  from cons  sorted_Cons have tt: "(\<forall>y\<in>set (s#ss). s \<le> y)" by auto
  with cons  have tt': "(\<forall>y\<in>set ss. s < y)"
  proof -
    from sss have "(\<forall>y\<in>set ss. s \<noteq> y)" by auto
    with tt show ?thesis by fastforce
  qed
    
  then have "{(x, y) . x = s \<and> y \<in> set ss \<and> x < y}
          = {(x, y) . x = s \<and> y \<in> set ss}" by auto
  also have "\<dots> = {s}\<times>(set ss)" by auto
  finally have "{(x, y) . x = s \<and> y \<in> set ss \<and> x < y} = {s}\<times>(set ss)" .
  then have "card {(x, y) . x = s \<and> y \<in> set ss \<and> x < y}
          = card (set ss)" by(auto)
  also from cons distinct_card have "\<dots> = length ss" by auto
  finally have step: "card {(x, y) . x = s \<and> y \<in> set ss \<and> x < y} =
            length ss" .

  have uni: "{(x, y) . x \<in> set (s # ss) \<and> y \<in> set (s # ss) \<and> x < y}
      = {(x, y) . x \<in> set ss \<and> y \<in> set ss \<and> x < y}
        \<union> {(x, y) . x = s \<and> y \<in> set ss \<and> x < y}"
        using tt by auto

  have disj: "{(x, y) . x \<in> set ss \<and> y \<in> set ss \<and> x < y}
        \<inter> {(x, y) . x = s \<and> y \<in> set ss \<and> x < y} = {}"
          using sss by(auto)
  have "card {(x, y) . x \<in> set (s # ss) \<and> y \<in> set (s # ss) \<and> x < y}
    = card ({(x, y) . x \<in> set ss \<and> y \<in> set ss \<and> x < y}
        \<union> {(x, y) . x = s \<and> y \<in> set ss \<and> x < y})" using uni by auto
  also have "\<dots> = card {(x, y) . x \<in> set ss \<and> y \<in> set ss \<and> x < y}
          + card {(x, y) . x = s \<and> y \<in> set ss \<and> x < y}" 
       apply(rule card_Un_disjoint)
          apply(rule finite_subset[where B="(set ss) \<times> (set ss)"])
           apply(force)
          apply(simp)
         apply(rule finite_subset[where B="{s} \<times> (set ss)"])
          apply(force)
         apply(simp)
         using disj apply(simp) done
  also have "\<dots> = (length ss * (length ss-1)) / 2
                  + length ss" using iH step by auto
  also have "\<dots> = (length ss * (length ss-1) + 2*length ss) / 2" by auto
  also have "\<dots> = (length ss * (length ss-1) + length ss * 2) / 2" by auto
  also have "\<dots> = (length ss * (length ss-1+2)) / 2"
    by simp
  also have "\<dots> = (length ss * (length ss+1)) / 2"
    using cons(1) by simp
  also have "\<dots> = ((length ss+1) * length ss) / 2" by auto
  also have "\<dots> = (length (s#ss) * (length (s#ss)-1)) / 2" by auto
  finally show ?case by auto
next
  case single thus ?case by(simp cong: conj_cong)
qed


(* factoring lemma *)
lemma factoringlemma_withconstant:
    fixes A
          and b::real
          and c::real
      assumes c: "c \<ge> 1"
      assumes dist: "\<forall>e\<in>S0. distinct e"
      assumes notempty: "\<forall>e\<in>S0. length e > 0"
      (* A has pairwise property *)
      assumes pw: "pairwise A"
      (* A is c-competitive on list of length 2 *) 
      assumes on2: "\<forall>s0\<in>S0. \<exists>b\<ge>0. \<forall>qs\<in>{x. set x \<subseteq> set s0}. \<forall>(x,y)\<in>{(x,y). x \<in> set s0 \<and> y\<in>set s0 \<and> x<y}. T\<^sub>p_on_rand A (Lxy s0 {x,y}) (Lxy qs {x,y})  \<le> c * (T\<^sub>p_opt (Lxy s0 {x,y}) (Lxy qs {x,y})) + b" 
      assumes nopaid: "\<And>is s q. \<forall>((free,paid),_) \<in> (snd A (s, is) q). paid=[]"
      assumes 4: "\<And>init qs. distinct init \<Longrightarrow> set qs \<subseteq> set init \<Longrightarrow> (\<And>x. x<length qs \<Longrightarrow> finite (set_pmf (config'' A qs init x)))" 
      (* then A is c-competitive on arbitrary list lengths *)
      shows "\<forall>s0\<in>S0. \<exists>b\<ge>0.  \<forall>qs\<in>{x. set x \<subseteq> set s0}. 
              T\<^sub>p_on_rand A s0 qs \<le> c * real (T\<^sub>p_opt s0 qs) + b"
proof 
  case (goal1 init)
    have d: "distinct init" using  dist goal1 by auto
    have d2: "init \<noteq> []" using  notempty goal1 by auto


    obtain b where on3: "\<forall>qs\<in>{x. set x \<subseteq> set init}. \<forall>(x,y)\<in>{(x,y). x \<in> set init \<and> y\<in>set init \<and> x<y}. T\<^sub>p_on_rand A  (Lxy init {x,y}) (Lxy qs {x,y}) \<le> c * (T\<^sub>p_opt (Lxy init {x,y}) (Lxy qs {x,y})) + b"
        and b: "b\<ge>0"
      using on2 goal1 by auto

  {

    fix qs
    assume drin: "set qs \<subseteq> set init"
  thm setsum_mono 

  thm umf_pair
  have "T\<^sub>p_on_rand A init qs =
(\<Sum>(x,y)\<in>{(x, y) . x \<in> set init \<and> y \<in> set init \<and> x < y}.
       T\<^sub>p_on_rand A (Lxy init {x,y}) (Lxy qs {x, y})) "
       apply(rule umf_pair)
        apply(fact)+
        using 4[of init qs] drin d by(simp add: split_def)
       (* 1.4 *) 
  also have "\<dots> \<le> (\<Sum>(x,y)\<in>{(x,y). x \<in> set init \<and> y\<in>set init \<and> x<y}. c * (T\<^sub>p_opt (Lxy init {x,y}) (Lxy qs {x,y})) + b)"
        apply(rule setsum_mono)
        using on3 drin by(simp add: split_def) 
        thm setsum_right_distrib setsum.distrib
  also have "\<dots> = c * (\<Sum>(x,y)\<in>{(x,y). x \<in> set init \<and> y\<in>set init \<and> x<y}. T\<^sub>p_opt (Lxy init {x,y}) (Lxy qs {x,y})) + b*(((length init)*(length init-1)) / 2)"
  proof - 

    {
      fix S::"'a list"
      assume dis: "distinct S"
      assume d2: "S \<noteq> []"
      then have d3: "sort S \<noteq> []" by (metis length_0_conv length_sort)
      have "card {(x,y). x \<in> set S \<and> y\<in>set S \<and> x<y}
            = card {(x,y). x \<in> set (sort S) \<and> y\<in>set (sort S) \<and> x<y}"
            by auto
      also have "\<dots> = (length (sort S) * (length (sort S) - 1)) / 2"
        apply(rule cardofpairs) using dis d2 d3 by (simp_all)
      finally have "card {(x, y) . x \<in> set S \<and> y \<in> set S \<and> x < y} =
              (length (sort S) * (length (sort S) - 1)) / 2 " .      
    }
    with d d2 have e: "card {(x,y). x \<in> set init \<and> y\<in>set init \<and> x<y} = ((length init)*(length init-1)) / 2" by auto
    show ?thesis  (is "(\<Sum>(x,y)\<in>?S. c * (?T x y) + b) = c * ?R + b*?T2")
    proof -
       have "(\<Sum>(x,y)\<in>?S. c * (?T x y) + b) =
              c * (\<Sum>(x,y)\<in>?S. (?T x y)) + (\<Sum>(x,y)\<in>?S. b)"
              by(simp add: split_def setsum.distrib setsum_right_distrib)
       also have "\<dots> = c * (\<Sum>(x,y)\<in>?S. (?T x y)) + b*?T2"
          using e by(simp add: split_def)
       finally show ?thesis by(simp add: split_def)
    qed
  qed
  also have "\<dots> \<le> c * T\<^sub>p_opt init qs + (b*((length init)*(length init-1)) / 2)"
    proof -
      have "(\<Sum>(x, y)\<in>{(x, y) . x \<in> set init \<and>
              y \<in> set init \<and> x < y}. T\<^sub>p_opt (Lxy init {x,y}) (Lxy qs {x, y}))
              \<le>  T\<^sub>p_opt init qs"
              using OPT_zerlegen drin d by auto    
      then have "  (\<Sum>(x, y)\<in>{(x, y) . x \<in> set init \<and>
              y \<in> set init \<and> x < y}. T\<^sub>p_opt (Lxy init {x,y}) (Lxy qs {x, y}))
              \<le>    (T\<^sub>p_opt init qs)"
              by blast    
      with c show ?thesis sorry (* auto *)
    qed
  finally have f: "T\<^sub>p_on_rand A init qs \<le> c * real (T\<^sub>p_opt init qs) + (b*((length init)*(length init-1)) / 2)" .
  } note all=this
  show ?case unfolding compet_def
    apply(auto)
      apply(rule exI[where x="(b*((length init)*(length init-1)) / 2)"])
      apply(safe)
        using notempty goal1 b apply simp
        using all b by simp
qed

lemma factoringlemma_withconstant':
    fixes A
          and b::real
          and c::real
      assumes c: "c \<ge> 1"
      assumes dist: "\<forall>e\<in>S0. distinct e"
      assumes notempty: "\<forall>e\<in>S0. length e > 0"
      (* A has pairwise property *)
      assumes pw: "pairwise A"
      (* A is c-competitive on list of length 2 *) 
      assumes on2: "\<forall>s0\<in>S0. \<exists>b\<ge>0. \<forall>qs\<in>{x. set x \<subseteq> set s0}. \<forall>(x,y)\<in>{(x,y). x \<in> set s0 \<and> y\<in>set s0 \<and> x<y}. T\<^sub>p_on_rand A (Lxy s0 {x,y}) (Lxy qs {x,y})  \<le> c * (T\<^sub>p_opt (Lxy s0 {x,y}) (Lxy qs {x,y})) + b" 
      assumes nopaid: "\<And>is s q. \<forall>((free,paid),_) \<in> (snd A (s, is) q). paid=[]"
      assumes 4: "\<And>init qs. distinct init \<Longrightarrow> set qs \<subseteq> set init \<Longrightarrow> (\<And>x. x<length qs \<Longrightarrow> finite (set_pmf (config'' A qs init x)))" 
      (* then A is c-competitive on arbitrary list lengths *)
      shows "compet_rand A c S0"
unfolding compet_rand_def static_def using factoringlemma_withconstant[OF assms] by simp

(*
 

(* Lemma 1.3 *)
lemma costindependet: "compet\<^sub>p A c S0 \<Longrightarrow> compet A c SO"
sorry
 

*)

end