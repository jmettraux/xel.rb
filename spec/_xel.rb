
#
# spec/_xel.rb

[

{:c=>
  "AND(\n" +
  "        NOT(apac_currency),\n" +
  "        OR(cm_rating_top_out_or_sector, jpm_overweight_or_neutral),\n" +
  "        moat_narrow_or_wide)",
 :ctx=>
  {:apac_currency=>true,
   :cm_rating_top_out_or_sector=>true,
   :jpm_overweight_or_neutral=>false,
   :moat_narrow_or_wide=>false},
 :o=>false},

{:c=>
  "AND(\n" +
  "        NOT(meta.apac_currency),\n" +
  "        OR(meta.cm_rating_top_out_or_sector, meta.jpm_overweight_or_neutral),\n" +
  "        meta.moat_narrow_or_wide)",
 :ctx=>
  {:meta=>
    {:apac_currency=>false,
     :cm_rating_top_out_or_sector=>true,
     :jpm_overweight_or_neutral=>false,
     :moat_narrow_or_wide=>true}},
 :o=>true},

{:c=>
  "AND(\n" +
  "        meta.apac_currency,\n" +
  "        OR(meta.ms_rating_overall_543, meta.jpm_overweight_or_neutral),\n" +
  "        meta.moat_narrow_or_wide,\n" +
  "        meta.esg_risk_low_medium_or_negligible,\n" +
  "        NOT(AND(meta.ms_rating_overall_3, meta.jpm_neutral)))",
 :ctx=>
  {:meta=>
    {:apac_currency=>true,
     :ms_rating_overall_3=>false,
     :ms_rating_overall_543=>true,
     :moat_narrow_or_wide=>true,
     :esg_risk_low_medium_or_negligible=>true}},
 :o=>true}

]

