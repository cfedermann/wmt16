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
