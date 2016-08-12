# Description

This directory includes the collected human judgments from the WMT16
human evaluation. It can be downloaded from:

    http://statmt.org/wmt16/results.html
    
If you use this data, please cite the following paper:

    @InProceedings{bojar-EtAl:2016:WMT1,
      author    = {Bojar, Ond\v{r}ej  and  Chatterjee, Rajen and Federmann, Christian  and  Graham, Yvette  and  Haddow, Barry  and  Huck, Matthias  and  Jimeno Yepes, Antonio  and  Koehn, Philipp  and  Logacheva, Varvara  and  Monz, Christof  and  Negri, Matteo  and  Neveol, Aurelie  and  Neves, Mariana  and  Popel, Martin  and  Post,  Matt  and  Rubino, Raphael  and  Scarton, Carolina  and  Specia,  Lucia  and  Turchi, Marco  and  Verspoor, Karin  and  Zampieri,  Marcos},
      title     = {Findings of the 2016 Conference on Machine Translation},
      booktitle = {Proceedings of the First Conference on Machine Translation},
      month     = {August},
      year      = {2016},
      address   = {Berlin, Germany},
      publisher = {Association for Computational Linguistics},
      pages     = {131--198},
      url       = {http://www.aclweb.org/anthology/W/W16/W16-2301}
    }

That paper includes details about how the official system ranking was computed. 
Additional techical details can be found below.

# Data file format

The human rankings were collected using [Appraise](https://github.com/cfedermann/Appraise). 
Appraise exports an XML file containing HIT information, which is then converted to the standard
CSV file format used by WMT scripts. The CSV files under data/ have the following format:

    srclang,trglang,srcIndex,segmentId,judgeID,system1Id,system1rank,system2Id,system2rank,rankingID
    cze,eng,779,779,judge1,newstest2016.uedin-nmt.4361.cs-en,5,newstest2016.online-A.0.cs-en,3,1
    ....

- srclang and trglang are the ISO 639-2 source and target codes
- srcIndex and segmentId both denote the 1-indexed segment number. Note that, due to a bug in the
  sentence sampling, data was only sampled from the first third of the sentences in the test set.
  The highest ID is therefore 1065.
- judgeID is an anonymized ID identifying each judge
- system1Id and system2Id identify the systems being judged
- system1rank and system2rank denote the system ranks that were assigned (1 is the best, 5 the worst).
- rankingID associates pairwise comparisons that came from the same ranking task.

# How to produce the WMT human rankings

0. If you *really* want to start from the beginning, download the raw XML dump of the 
   ranking tasks from [Appraise](http://appraise.cf/admin/wmt16/hit/) and save it
   as data/wmt16.xml.gz. Then run

        cd data
        python xml2csv.py wmt16.xml.gz

   This will generate wmt16.XXX.csv files, one for each language pair, and anonymize the
   judges.

   Note that WMT16 had judges compare unique outputs, instead of system outputs, as was
   also done for WMT15. Rankings were then assigned to all systems that had a unique
   output. For this reason, the WMT CSV file has a slightly different format: each line
   is a pairwise (2-way) comparison instead of a 5-way one. The last field, rankingID, groups
   together the judgments that were in an individual ranking task.

1. Now, to compute the rankings. Install wmt-trueskill:

        git clone https://github.com/keisks/wmt-trueskill

2. Install the trueskill code

        cd wmt-trueskill/src
        git clone https://github.com/sublee/trueskill

3. Compute the rankings. If you're on a SGE-compatible cluster, you should be able to submit
   this as an array job:

        for lang in $(ls data/wmt16*csv | cut -d. -f2); do 
          qsub scripts/run-1000.sh ts $type
        done

   If you're not on a cluster, you'll have to run them sequentially. The command to use is:

        for lang in $(ls data/wmt16*csv | cut -d. -f2); do 
          for num in $(seq 1 1000); do
            SGE_TASK_ID=$num ./scripts/run-1000.sh ts $type
          done
        done

4. Compute the clusters

        for lang in $(ls data/wmt16*csv | cut -d. -f2); do 
          ./wmt-trueskill/eval/cluster.py -by-rank results/$lang/ts/*/*.json > results/wmt16.$lang.txt
        done

5. That's it! Please direct questions to Matt Post.

# How to compute annotator agreement

Note that annotator agreement has been computed on the ``collapsed'' rankings.
Otherwise, we would have artificially boosted our agreemetn scores.

1. Export collapsed CSV rankings

        cp wmt16.xml.gz wmt16.collapsed.xml.gz
        python xml2csv.py -c wmt16.collapsed.xml.gz
    
    This will produce individual files for all language pairs as well as an `wmt16.collapsed.all.csv` file containing all rankings.
    Note that `xml2csv.py` will overwrite files in place, so renaming the archive is a good idea before running this :)

2. Compute inter-annotator agreement

        python compute_agreement_scores.py wmt16.collapsed.all.csv --verbose --inter

    This will create the following output

        Language pair        pA     pE     kappa  (agree, comparable, ties, total)
           Czech-English  0.510  0.351  0.244     9370    18389     9836    43991
           English-Czech  0.607  0.366  0.381    11900    19594    14465    77948
          German-English  0.696  0.421  0.475      749     1076     1182    12926
          English-German  0.605  0.373  0.369     2018     3338     5073    29770
         Russian-English  0.569  0.349  0.339     1410     2476     4742    20520
         English-Russian  0.562  0.336  0.340     1565     2786     7307    25117
         Finnish-English  0.532  0.338  0.293     2125     3998     7180    25637
         English-Finnish  0.702  0.423  0.484     1925     2742     2335    26172
        Romanian-English  0.586  0.371  0.341     1793     3062     2101    11978
        English-Romanian  0.593  0.345  0.379      302      509     2110     8642
         Turkish-English  0.554  0.345  0.319      349      630     2367     9684
         English-Turkish  0.548  0.334  0.322      403      735     3540    10095

3. Compute intra-annotator agreement

        python compute_agreement_scores.py wmt16.collapsed.all.csv --verbose --intra

    This will create the following output

            Language pair        pA     pE     kappa  (agree, comparable, ties, total)
           Czech-English  0.670  0.334  0.504      700     1045     1704     5575
           English-Czech  0.635  0.350  0.438     1861     2932     5680    24827
          German-English  0.754  0.450  0.552      101      134       64     1182
          English-German  0.698  0.360  0.529      264      378      606     3033
         Russian-English  0.705  0.341  0.552      155      220      514     1968
         English-Russian  0.686  0.334  0.528      227      331     1267     3600
         Finnish-English  0.710  0.357  0.549      360      507     1854     4042
         English-Finnish  0.790  0.451  0.617      432      547      256     4802
        Romanian-English  0.755  0.355  0.621      139      184      227     1060
        English-Romanian  0.704  0.340  0.552      119      169      401     1509
         Turkish-English  0.714  0.352  0.559       45       63      136      610
         English-Turkish  0.574  0.343  0.352      116      202      764     1843

