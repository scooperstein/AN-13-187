# Makefile to generate limit cards for VH
#
# Targets:
#
# llt, ltt, zh: generate cards and put them in auxiliaries/datacards
# cards: generate all cards (from above)
#
# limitdir: generate limit computation project area
#
# pulls: compute the pulls.  Stored in pulls/125
#
# massplots: make the pre and postfit plots
#
# limits: compute all the limits
#
# plotlimits: make limit plots
#
# plots/vh_table.tex: generate tex table
#
# all: do everything!

# Working directory
BASE=$(CMSSW_BASE)/src
WD=$(BASE)/AN-13-187

# Location of the CGS and uncertainty configuration files
SETUP=$(BASE)/HiggsAnalysis/HiggsToTauTau/setup/vhtt
HTT_TEST=$(BASE)/HiggsAnalysis/HiggsToTauTau/test

# where the limit directory lives (in HIG-12-053) 
LIMITDIR=$(WD)/limits

# where the raw generated cards are generated.
CARDDIR=$(BASE)/auxiliaries/datacards
CARDS=$(BASE)/auxiliaries/datacards/sm/vhtt
COLLECT=$(BASE)/auxiliaries/datacards/collected/vhtt


################################################################################
#####  Recipes for combining all shape files ###################################
################################################################################

# Combine all 8TeV shape files
$(SETUP)/vhtt.inputs-sm-8TeV.root: $(COLLECT)/vhtt_llt.inputs-sm-8TeV.root $(COLLECT)/vhtt_llLL.inputs-sm-8TeV.root $(COLLECT)/vhtt_ltt.inputs-sm-8TeV.root
	hadd -f $@ $^

# Combine all 7TeV shape files - we just take these from the HCP cards for 
# LLT and ZH
$(SETUP)/vhtt.inputs-sm-7TeV.root: $(COLLECT)/vhtt_llt.inputs-sm-7TeV.root $(COLLECT)/vhtt_llLL.inputs-sm-7TeV.root $(COLLECT)/vhtt_ltt.inputs-sm-7TeV.root
	hadd -f $@ $^

SHAPEFILE7=$(SETUP)/vhtt.inputs-sm-7TeV.root
SHAPEFILE8=$(SETUP)/vhtt.inputs-sm-8TeV.root
#SHAPEFILE8=$(SETUP)/vhtt.inputs-sm-8TeV_scaled.root

## scale to 13 TeV and 300/fb
scale_to_13TeV: $(SHAPEFILE8)
	scaleTo13TeV.py -i $(SHAPEFILE8) -o $(SHAPEFILE8)_scaled \
	ZH=ZH_htt110,ZH_htt115,ZH_htt120,ZH_htt125,ZH_htt130,ZH_htt135,ZH_htt140,\
	ZH_hww110,ZH_hww115,ZH_hww120,ZH_hww125,ZH_hww130,ZH_hww135,ZH_hww140, Z=Zjets ZZ=ZZ,zz,GGToZZ2L2L WZ=wz WH=WH110,\
	WH115,WH120,WH125,WH130,WH135,WH140,WH145,WH150,WH155,WH160,WH_hww110,WH_hww115,WH_hww120,WH_hww125,WH_hww130,\
	WH_hww135,WH_hww140,WH_hww145,WH_hww150,WH_hww155,WH_hww160
	mv $(SHAPEFILE8)_scaled $(SHAPEFILE8)
	cd $(SETUP)/.. && ./scale-lumi.py --channels=vhtt 20 300 
	#$(SETUP)/../scale-lumi.py --channels=vhtt 20 300
	scale-uncerts.py --scale=0.258 $(CARDS)/vhtt*8TeV*.txt

################################################################################
#####  Recipes for building EMT and MMT cards ##################################
################################################################################

LLT_CONFIGS7=$(wildcard $(SETUP)/*-sm-7TeV-00.*)
LLT_CONFIGS8=$(wildcard $(SETUP)/*-sm-8TeV-00.* $(SETUP)/*-sm-8TeV-01.* $(SETUP)/*-sm-8TeV-02.*)

# Recipe for building LLT cards
$(CARDS)/.llt7_timestamp: $(SHAPEFILE7) $(LLT_CONFIGS7)
	@echo "Recipes for building EET, EMT and MMT cards 7TeV"
	rm -f $(CARDS)/vhtt_0_7TeV*
	rm -f $(CARDS)/vhtt_1_7TeV*
	rm -f $(CARDS)/vhtt_2_7TeV*
	# $@ is the .timestamp file
	rm -f $@
	# change to base, run the setup command, and touch the .timestamp if 
	# successful
	cd $(BASE) && setup-datacards.py -p 7TeV --a sm 110-145:5 -c vhtt --sm-categories-vhtt "0 1 2 3 4 5 6 7 8" && touch $@

$(CARDS)/.llt8_timestamp: $(SHAPEFILE8) $(LLT_CONFIGS8)
	@echo "Recipes for building EET, EMT and MMT cards 8TeV"
	rm -f $(CARDS)/vhtt_0_8TeV*
	rm -f $(CARDS)/vhtt_1_8TeV*
	rm -f $(CARDS)/vhtt_2_8TeV*
	rm -f $@
	cd $(BASE) && setup-datacards.py -p 8TeV --a sm 110-145:5 -c vhtt --sm-categories-vhtt "0 1 2 3 4 5 6 7 8" && touch $@

#llt: $(CARDS)/.llt7_timestamp $(CARDS)/.llt8_timestamp
llt: $(CARDS)/.llt8_timestamp

################################################################################
#####  Recipes for building ZH cards ###########################################
################################################################################

ZH_CONFIGS7=$(wildcard $(SETUP)/*-sm-7TeV-01.*)
ZH_CONFIGS8=$(wildcard $(SETUP)/*-sm-8TeV-03.* $(SETUP)/*-sm-8TeV-04.* $(SETUP)/*-sm-8TeV-05.* $(SETUP)/*-sm-8TeV-06.*)

# Recipe for building ZH cards
$(CARDS)/.zh7_timestamp: $(SHAPEFILE7) $(ZH_CONFIGS7)
	@echo "Recipes for building ZH cards 7TeV"
	rm -f $(CARDS)/vhtt_1_7TeV*
	rm -f $@
	cd $(BASE) && setup-datacards.py -p 7TeV --a sm 110-145:5 -c vhtt --sm-categories-vhtt 1 && touch $@

$(CARDS)/.zh8_timestamp: $(SHAPEFILE8) $(ZH_CONFIGS8)
	@echo "Recipes for building ZH cards 8TeV"
	rm -f $(CARDS)/vhtt_3_8TeV*
	rm -f $(CARDS)/vhtt_4_8TeV*
	rm -f $(CARDS)/vhtt_5_8TeV*
	rm -f $(CARDS)/vhtt_6_8TeV*
	rm -f $@
	cd $(BASE) && setup-datacards.py -p 8TeV --a sm 110-145:5 -c vhtt --sm-categories-vhtt "3 4 5 6" && touch $@

#zh: $(CARDS)/.zh7_timestamp $(CARDS)/.zh8_timestamp
zh: $(CARDS)/.zh8_timestamp

################################################################################
#####  Recipes for building LTT cards ##########################################
################################################################################

LTT_CONFIGS7=$(wildcard $(SETUP)/*-sm-7TeV-02.*)
LTT_CONFIGS8=$(wildcard $(SETUP)/*-sm-8TeV-07.* $(SETUP)/*-sm-8TeV-08.*)

# Recipe for building LTT cards
$(CARDS)/.ltt7_timestamp: $(SHAPEFILE7) $(LTT_CONFIGS7)
	@echo "Recipes for building LTT cards 7TeV"
	rm -f $(CARDS)/vhtt_2_7TeV*
	rm -f $@
	cd $(BASE) && setup-datacards.py -p 7TeV --a sm 110-145:5 -c vhtt --sm-categories-vhtt 2 && ls $(CARDS)/vhtt_2_7TeV* | xargs -n1 -I{} $(WD)/prune_signal_uncertainties_ltt.py {} && touch $@

$(CARDS)/.ltt8_timestamp: $(SHAPEFILE8) $(LTT_CONFIGS8)
	@echo "Recipes for building LTT cards 8TeV"
	rm -f $(CARDS)/vhtt_7_8TeV*
	rm -f $(CARDS)/vhtt_8_8TeV*
	rm -f $@
	cd $(BASE) && setup-datacards.py -p 8TeV --a sm 110-145:5 -c vhtt --sm-categories-vhtt "7 8" && ls $(CARDS)/vhtt_7_8TeV* $(CARDS)/vhtt_8_8TeV* | xargs -n1 -I{} $(WD)/prune_signal_uncertainties_ltt.py {} && touch $@

#ltt: $(CARDS)/.ltt7_timestamp $(CARDS)/.ltt8_timestamp
ltt: $(CARDS)/.ltt8_timestamp

cards: scale_to_13TeV zh ltt llt
#cards: zh ltt llt

################################################################################
#####  Recipes for generating the limit combo directory ########################
################################################################################

$(LIMITDIR)/.timestamp:  $(CARDS)/.ltt8_timestamp \
  $(CARDS)/.zh8_timestamp \
  $(CARDS)/.llt8_timestamp
	rm -rf $(LIMITDIR)
	cd $(BASE) && setup-htt.py -o $(LIMITDIR) -c vhtt --sm-categories-vhtt "0 1 2 3 4 5 6 7 8" 110-145:5 && touch $@


limitdir: $(LIMITDIR)/.timestamp

################################################################################
#####  The single card which has everything at 125 -used to make plots #########
################################################################################

megacard_125.txt: $(LIMITDIR)/.timestamp
	combineCards.py \
	0_8TeV = $(LIMITDIR)/cmb/125/vhtt_0_8TeV.txt \
	1_8TeV = $(LIMITDIR)/cmb/125/vhtt_1_8TeV.txt \
	2_8TeV = $(LIMITDIR)/cmb/125/vhtt_2_8TeV.txt \
	3_8TeV = $(LIMITDIR)/cmb/125/vhtt_3_8TeV.txt \
	4_8TeV = $(LIMITDIR)/cmb/125/vhtt_4_8TeV.txt \
	5_8TeV = $(LIMITDIR)/cmb/125/vhtt_5_8TeV.txt \
	6_8TeV = $(LIMITDIR)/cmb/125/vhtt_6_8TeV.txt \
	7_8TeV = $(LIMITDIR)/cmb/125/vhtt_7_8TeV.txt \
	8_8TeV = $(LIMITDIR)/cmb/125/vhtt_8_8TeV.txt > $@
	#0_7TeV = $(LIMITDIR)/cmb/125/vhtt_0_7TeV.txt \
        1_7TeV = $(LIMITDIR)/cmb/125/vhtt_1_7TeV.txt \
        2_7TeV = $(LIMITDIR)/cmb/125/vhtt_2_7TeV.txt \
        3_7TeV = $(LIMITDIR)/cmb/125/vhtt_3_7TeV.txt \
        4_7TeV = $(LIMITDIR)/cmb/125/vhtt_4_7TeV.txt \
        5_7TeV = $(LIMITDIR)/cmb/125/vhtt_5_7TeV.txt \
        6_7TeV = $(LIMITDIR)/cmb/125/vhtt_6_7TeV.txt \
        7_7TeV = $(LIMITDIR)/cmb/125/vhtt_7_7TeV.txt \
        8_7TeV = $(LIMITDIR)/cmb/125/vhtt_8_7TeV.txt > $@
	  #llt7TeV=$(LIMITDIR)/cmb/125/vhtt_0_7TeV.txt \
	  #llt8TeV=$(LIMITDIR)/cmb/125/vhtt_0_8TeV.txt \
	  #ZH7TeV=$(LIMITDIR)/cmb/125/vhtt_1_7TeV.txt \
	  #ZH8TeV=$(LIMITDIR)/cmb/125/vhtt_1_8TeV.txt \
	  #ltt7TeV=$(LIMITDIR)/cmb/125/vhtt_2_7TeV.txt \
	  #ltt8TeV=$(LIMITDIR)/cmb/125/vhtt_2_8TeV.txt > $@
	

################################################################################
#####  Computing the pulls  ####################################################
################################################################################

pulls/.timestamp: $(LIMITDIR)/.timestamp do_pull.sh
	rm -rf pulls
	mkdir -p pulls
	cp -r $(LIMITDIR)/cmb/125 pulls/125
	cp -r $(LIMITDIR)/cmb/common pulls/common	
	./do_pull.sh && touch $@

pulls: pulls/.timestamp

################################################################################
#####  Computing the limits ####################################################
################################################################################

NPROCS=10

$(LIMITDIR)/.computed: $(LIMITDIR)/.timestamp
	echo "Computing combined limits"
	./compute_limits.sh cmb $(NPROCS)
	echo "Computing ZH combined limits"
	./compute_limits.sh vhtt_zh $(NPROCS)
	echo "Computing separated ZH limits"
	./compute_limits.sh vhtt_zh_llll $(NPROCS)
	./compute_limits.sh vhtt_zh_lllt $(NPROCS)
	./compute_limits.sh vhtt_zh_lltt $(NPROCS)
	echo "Computing LLT limits"
	./compute_limits.sh vhtt_wh $(NPROCS)
	echo "Computing LTT limits"
	./compute_limits.sh vhtt_wh_had $(NPROCS)
	#echo "Computing WH limits"
	#./compute_limits.sh vhtt_wh $(NPROCS)
	touch $@

limits: $(LIMITDIR)/.computed

################################################################################
#####  Plotting the limits #####################################################
################################################################################

# This dumb macro needs to be compiled.
$(BASE)/HiggsAnalysis/HiggsToTauTau/macros/compareLimits_C.so: $(BASE)/HiggsAnalysis/HiggsToTauTau/macros/compareLimits.C
	cd $(BASE) && source HiggsAnalysis/HiggsToTauTau/environment.sh

comparemacro: $(BASE)/HiggsAnalysis/HiggsToTauTau/macros/compareLimits_C.so

$(LIMITDIR)/.plot_timestamp: $(LIMITDIR)/.computed $(BASE)/HiggsAnalysis/HiggsToTauTau/python/layouts/sm_vhtt_*.py
	rm -f $@
	# If you forget the trailing slash on the plot directory it will fuck up
	##cd $(LIMITDIR) && plot --asymptotic $(BASE)/HiggsAnalysis/HiggsToTauTau/python/layouts/sm_vhtt_layout.py llt/ 
	##cd $(LIMITDIR) && plot --asymptotic $(BASE)/HiggsAnalysis/HiggsToTauTau/python/layouts/sm_vhtt_layout.py 4l/ 
	##cd $(LIMITDIR) && plot --asymptotic $(BASE)/HiggsAnalysis/HiggsToTauTau/python/layouts/sm_vhtt_layout.py ltt/ max=50 
	##cd $(LIMITDIR) && plot --asymptotic $(BASE)/HiggsAnalysis/HiggsToTauTau/python/layouts/sm_vhtt_layout.py cmb/ 
	#cd $(LIMITDIR) && plot --asymptotic $(BASE)/HiggsAnalysis/HiggsToTauTau/python/layouts/sm_vhtt_layout.py vhtt_zh/
	cd $(LIMITDIR) && plot --asymptotic $(BASE)/HiggsAnalysis/HiggsToTauTau/python/layouts/sm_vhtt_exp_layout.py vhtt_zh/
	cd $(LIMITDIR) && plot --asymptotic $(BASE)/HiggsAnalysis/HiggsToTauTau/python/layouts/sm_vhtt_exp_layout.py vhtt_zh_llll/
	cd $(LIMITDIR) && plot --asymptotic $(BASE)/HiggsAnalysis/HiggsToTauTau/python/layouts/sm_vhtt_exp_layout.py vhtt_zh_lllt/
	cd $(LIMITDIR) && plot --asymptotic $(BASE)/HiggsAnalysis/HiggsToTauTau/python/layouts/sm_vhtt_exp_layout.py vhtt_zh_lltt/
	cd $(LIMITDIR) && plot --asymptotic $(BASE)/HiggsAnalysis/HiggsToTauTau/python/layouts/sm_vhtt_exp_layout.py vhtt_wh/
	cd $(LIMITDIR) && plot --asymptotic $(BASE)/HiggsAnalysis/HiggsToTauTau/python/layouts/sm_vhtt_exp_layout.py vhtt_wh_had/
	cd $(LIMITDIR) && plot --asymptotic $(BASE)/HiggsAnalysis/HiggsToTauTau/python/layouts/sm_vhtt_exp_layout.py cmb/
	#cd $(LIMITDIR) && plot --asymptotic $(BASE)/HiggsAnalysis/HiggsToTauTau/python/layouts/sm_vhtt_exp_layout.py ltt/ max=25 
	#cd $(LIMITDIR) && plot --asymptotic $(BASE)/HiggsAnalysis/HiggsToTauTau/python/layouts/sm_vhtt_exp_layout.py cmb/ 
	# Combine the output of all the individual limit results into a single file.
	rm -f $(LIMITDIR)/limits_limit.root 
	hadd $(LIMITDIR)/limits_limit.root $(LIMITDIR)/*_limit.root
	##cd $(LIMITDIR) && root -b -q '../../HiggsAnalysis/HiggsToTauTau/macros/compareLimits.C+("limits_limit.root", "cmb,4l,llt,ltt", true, false, "sm-xsex", 0, 25, false,"  Preliminary, VH#rightarrow#tau#tau, #sqrt{s} = 7-8 TeV, L=24 fb^{-1}")'
	##cd $(LIMITDIR) && root -b -q '../../HiggsAnalysis/HiggsToTauTau/macros/compareLimits.C+("limits_limit.root", "cmb,4l,llt,ltt", false, true, "sm-xsex", 0, 25, false,"  Preliminary, VH#rightarrow#tau#tau, #sqrt{s} = 7-8 TeV, L=24 fb^{-1}")'
	cd $(LIMITDIR) && root -b -q '../../HiggsAnalysis/HiggsToTauTau/macros/compareLimits.C+("limits_limit.root", "cmb,vhtt_zh_llll,vhtt_zh_lllt,vhtt_zh_lltt,vhtt_wh_had,vhtt_wh", true, false, "sm-xsex", 0, 25, false,"  Preliminary, VH#rightarrow#tau#tau, #sqrt{s} = 7-8 TeV, L=24 fb^{-1}")'
	#cd $(LIMITDIR) && root -b -q '../../HiggsAnalysis/HiggsToTauTau/macros/compareLimits.C+("limits_limit.root", "cmb,vhtt_zh_llll,vhtt_zh_lllt,vhtt_zh_lltt,vhtt_wh_had,vhtt_wh", false, true, "sm-xsex", 0, 25, false,"  Preliminary, VH#rightarrow#tau#tau, #sqrt{s} = 7-8 TeV, L=24 fb^{-1}")'
	touch $@

plots/.limits_timestamp: $(LIMITDIR)/.plot_timestamp
	mkdir -p plots
	cp $(LIMITDIR)/cmb_exp_limit.pdf plots/
	cp $(LIMITDIR)/cmb_exp_limit.tex plots/
	##cp $(LIMITDIR)/4l_limit.pdf plots/
	##cp $(LIMITDIR)/llt_limit.pdf plots/
	##cp $(LIMITDIR)/ltt_limit.pdf plots/
	##cp $(LIMITDIR)/cmb_limit.pdf plots/
	##cp $(LIMITDIR)/cmb_limit.tex plots/
	cp $(LIMITDIR)/vhtt_zh_exp_limit.pdf plots/
	cp $(LIMITDIR)/vhtt_zh_exp_limit.tex plots/
	cp $(LIMITDIR)/vhtt_zh_llll_exp_limit.pdf plots/
	cp $(LIMITDIR)/vhtt_zh_llll_exp_limit.tex plots/
	cp $(LIMITDIR)/vhtt_zh_lllt_exp_limit.pdf plots/
	cp $(LIMITDIR)/vhtt_zh_lllt_exp_limit.tex plots/
	cp $(LIMITDIR)/vhtt_zh_lltt_exp_limit.pdf plots/
	cp $(LIMITDIR)/vhtt_zh_lltt_exp_limit.tex plots/
	cp $(LIMITDIR)/vhtt_wh_exp_limit.pdf plots/
	cp $(LIMITDIR)/vhtt_wh_exp_limit.tex plots/
	cp $(LIMITDIR)/vhtt_wh_had_exp_limit.pdf plots/
	cp $(LIMITDIR)/vhtt_wh_had_exp_limit.tex plots/
	#cp $(LIMITDIR)/cmb_exp_limit.pdf plots/
	#cp $(LIMITDIR)/cmb_exp_limit.tex plots/
	#cp $(LIMITDIR)/ltt_exp_limit.pdf plots/
	cp $(LIMITDIR)/singleLimits_expected_sm.pdf plots/exp_limit_breakdown.pdf
	#cp $(LIMITDIR)/singleLimits_observed_sm.pdf plots/obs_limit_breakdown.pdf
	touch $@

plotlimits: plots/.limits_timestamp

################################################################################
#####  Making the post fit shape files for the nice plots ######################
################################################################################

# ML fit and copy the 125 combined mass point into the postfit zone
$(HTT_TEST)/.fit_timestamp: $(LIMITDIR)/.timestamp
	cd $(HTT_TEST) && ./mlfit_and_copy.py $(LIMITDIR)/cmb/125 && touch $@

# Make .root files with the applied pulls
$(HTT_TEST)/root_postfit/.timestamp: $(HTT_TEST)/.fit_timestamp
	# make a copy of the directory so we can mess with them.
	rm -fr $(HTT_TEST)/root_postfit
	cp -r $(HTT_TEST)/root $(HTT_TEST)/root_postfit
	# apply all the pulls to the shapes
	#cd $(HTT_TEST) && ./postfit.py root_postfit/vhtt.input_7TeV.root datacards/vhtt_1_7TeV.txt \
	#  --bins eemt_zh eeet_zh eeem_zh mmme_zh mmmt_zh mmet_zh eett_zh mmtt_zh \
	#  --verbose
	#cd $(HTT_TEST) && ./postfit.py root_postfit/vhtt.input_7TeV.root datacards/vhtt_0_7TeV.txt \
	#  --bins emt mmt --verbose
	cd $(HTT_TEST) && ./postfit.py root_postfit/vhtt.input_8TeV.root datacards/vhtt_3_8TeV.txt \
	  --bins eeem_zh mmme_zh \
	  --verbose
	cd $(HTT_TEST) && ./postfit.py root_postfit/vhtt.input_8TeV.root datacards/vhtt_4_8TeV.txt \
	  --bins eemt_zh mmmt_zh \
	  --verbose
	cd $(HTT_TEST) && ./postfit.py root_postfit/vhtt.input_8TeV.root datacards/vhtt_5_8TeV.txt \
	  --bins eeet_zh mmet_zh \
	  --verbose
	cd $(HTT_TEST) && ./postfit.py root_postfit/vhtt.input_8TeV.root datacards/vhtt_6_8TeV.txt \
	  --bins eett_zh mmtt_zh \
	  --verbose
	cd $(HTT_TEST) && ./postfit.py root_postfit/vhtt.input_8TeV.root datacards/vhtt_0_8TeV.txt \
	  --bins mmt --verbose
	cd $(HTT_TEST) && ./postfit.py root_postfit/vhtt.input_8TeV.root datacards/vhtt_1_8TeV.txt \
	  --bins emt --verbose
	cd $(HTT_TEST) && ./postfit.py root_postfit/vhtt.input_8TeV.root datacards/vhtt_2_8TeV.txt \
	  --bins eet --verbose
	cd $(HTT_TEST) && ./postfit.py root_postfit/vhtt.input_8TeV.root datacards/vhtt_7_8TeV.txt \
	  --bins mtt --verbose
	cd $(HTT_TEST) && ./postfit.py root_postfit/vhtt.input_8TeV.root datacards/vhtt_8_8TeV.txt \
	  --bins ett --verbose
	#cd $(HTT_TEST) && ./postfit.py root_postfit/vhtt.input_7TeV.root datacards/vhtt_2_7TeV.txt \
	#  --bins ett mtt --verbose
	# all done
	touch $@

plots/.mass_timestamp: $(HTT_TEST)/root_postfit/.timestamp pas_plots.py
	rm -rf plots
	mkdir -p plots
	#python pas_plots.py 
	python pas_plots.py --prefit --period 8TeV
	#python pas_plots.py --period 7TeV
	python pas_plots.py --period 8TeV
	touch $@

postfit: $(HTT_TEST)/root_postfit/.timestamp

massplots: plots/.mass_timestamp

################################################################################
#####  Making the yield tablespe files for the nice plots ######################
################################################################################

vh_table.tex: megacard_125.txt make_yields_table.py
	python make_yields_table.py

plots/vh_table.tex: vh_table.tex
	cp vh_table.tex plots/vh_table.tex

all: massplots plots/vh_table.tex plotlimits

clean:
	rm -f vh_table.tex
	rm -rf plots/
	rm -rf pulls
	rm -rf $(LIMITDIR)
	rm -rf $(SETUP)/*.root

.PHONY: cards scale_to_13TeV zh ltt llt limitdir pulls postfit massplots limits comparemacro plotlimits clean
