#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Mar 25 13:01:10 2020

@author: Chris Vriend, Jikke Boelens Keun, Eva van Heese.
"""

import pandas as pd
import matplotlib.pyplot as plt
import ptitprince as pt

import os
import numpy as np
import seaborn as sns
import argparse
#import plotly
#import chart_studio
#import plotly.tools as tls
import plotly.express as px
from plotly.subplots import make_subplots


sns.set(style="ticks",font_scale=2)



parser = argparse.ArgumentParser('extract volumes and make plots for QA')

# required arguments
parser.add_argument('--workdir', action="store", dest="workdir", required=True,
                    help='working directory, generally the SUBJECTS_DIR of FreeSurfer')
parser.add_argument('--outdir', action="store", dest="outdir", required=True,
                    help='output directory for csv files and plots')
parser.add_argument('--outbase', action="store", dest="outbase", required=True,
                                        help='base of output csv files')
parser.add_argument('--plotbase', action="store", dest="plotbase", required=True,
                                        help='base of output plot files ')
parser.add_argument('--segv', action="store", dest="segv", required=True,
                    help='version number of thalamic subsegmentation ')

args = parser.parse_args()

# generally SUBJECTS_DIR
workdir=args.workdir

# generally SUBJECTS_DIR/vol+QA
outputdir=args.outdir


outbase=args.outbase
#outbase='All'

# name base for vol QA html pages
plotbase=args.plotbase

# segmentation of amygdala hippocampus subsegmentation = v21
amygversion=args.segv

# specify index of subnuclei in dictionary
# Amygdala nuclei indexes are based on the text file in subject/stats/amygdalar-nuclei.${hemisphere}.T1.v21.stats
amygsubnuclei={}
amygsubnuclei['basolateral']=[1,2,3,9]
amygsubnuclei['centromedial']=[5,6]
amygsubnuclei['cortical_like_nuclei']=[7,8]
amygsubnuclei['whole_amygdala']=[10]

# anterior-amygdaloid-area AAA not taken into acccount


os.chdir(workdir)
print("Current Working Directory " , os.getcwd())

# list comprehension | find directories in work directory that start with sub-
subjdirs=[subjdirs for subjdirs in os.listdir(workdir)
      if (os.path.isdir(os.path.join(workdir, subjdirs)) and subjdirs.startswith('sub-'))];

# sort files and names
subjdirs.sort()

# define variables in which individual subject data are stored
# save variables in dataframe and export as amygdala-nuclei.v21.T1.stats

for subj in subjdirs:
    print(subj)
    # work and save files in stats directory
    os.chdir(os.path.join(workdir,subj,'stats'))
    # make empty dataframes before hemi loop

    df_amygbilat=pd.DataFrame()
    df_subnbilat=pd.DataFrame()
    df_amyggroup=pd.DataFrame()

    for hemi in ['lh','rh']:

        labelvol='volume_' + hemi
        labelnucl='nucleus_' + hemi

        df_amyg=pd.read_csv('amygdalar-nuclei.' + hemi + '.T1' + '.' + amygversion + '.stats',delim_whitespace=True,skiprows=1,
                            names=['ID','ID2','zero',labelvol,labelnucl],index_col='ID')
        # delete unneccesary columns
        df_amyg=df_amyg.drop(columns=(['ID2','zero']))

        # add hemi to nucleus label
        df_amyg[labelnucl]= df_amyg[labelnucl] + "_" + hemi

        df_subn=pd.DataFrame()

        # merge subnuclei to larger areas
        totalvol = np.array([])
        for subn,idx in amygsubnuclei.items():

            # print(subn + " " + hemi)

            # slice rows that belong to a particular nuclei group
            # and append to dataframe
            df_subn=df_subn.append(df_amyg.loc[idx,:])

            # calculate volume of nuclei group
            # and append to dataframe
            df_amyggroup=df_amyggroup.append({'nucleigroup' : subn + "_" + hemi,
                                              'volume': df_amyg.loc[idx,labelvol].sum()},ignore_index=True)
      #      totalvol=np.append(totalvol,df_amyg.loc[idx,labelvol].sum())
      #  df_amyggroup=df_amyggroup.append({'nucleigroup' : 'whole_amygdala' + "_" + hemi,
       #                                       'volume': np.sum(totalvol)},ignore_index=True)

    ### = subset of subnuclei also used for nucleus groups
        # rename columns
        df_subn=df_subn.rename(columns={labelnucl : 'nucleus', labelvol : 'volume'})
        # append hemispheres
        df_subnbilat=df_subnbilat.append(df_subn)

    ### = all  subnuclei
        # rename columns
        df_amyg=df_amyg.rename(columns={labelnucl : 'nucleus', labelvol : 'volume'})
        # append hemispheres
        df_amygbilat=df_amygbilat.append(df_amyg)

    # set index
    df_subnbilat=df_subnbilat.set_index('nucleus')
    df_amygbilat=df_amygbilat.set_index('nucleus')
    df_amyggroup=df_amyggroup.set_index('nucleigroup')

    # round volumes to 3 decimals and sort
    df_subnbilat=df_subnbilat.round(3).sort_values(by=['nucleus'])
    df_amygbilat=df_amygbilat.round(3).sort_values(by=['nucleus'])
    df_amyggroup=df_amyggroup.round(3).sort_values(by=['nucleigroup'])

    # save to csv file (for individual subjects)

    # define personal base directory!

    df_amygbilat.to_csv(os.path.join(subj + '_amyg_volume_subnuclei_all' + '.csv'), na_rep='NULL')
    df_subnbilat.to_csv(os.path.join(subj + '_amyg_volume_subnuclei' + '.csv')
                            ,na_rep='NULL')
    df_amyggroup.to_csv(os.path.join(subj + '_amyg_volume_nucleigroups' + '.csv')
                            ,na_rep='NULL')

################################################################################################
os.chdir(outputdir)

# Master DataFrame

# read txt files with WM and CSF overlap with Thalamus segmentations of entire sample

WMalltxtfile=outbase + "_WM_overlap_amygdala.txt"
CSFalltxtfile=outbase + "_CSF_overlap_amygdala.txt"

# this one needs to be created using FS aseg2statstable
# set SUBJECTS_DIR
# asegstats2table --subjects `cat subjects.txt` --tablefile asegstats.txt
asegallstatsfile=outbase + "_asegstats.txt"

# import the data for WM overlap with thalamus (stored in SUBJECTS_DIR)
df_WM = pd.read_csv(WMalltxtfile, delim_whitespace=True,
                    names = ["subject_ID","WM_overlay"], index_col=0)

#import the data for CSF overlap with thalamus (stored in SUBJECTS_DIR)
df_CSF = pd.read_csv(CSFalltxtfile, delim_whitespace=True,
                    names = ["subject_ID","CSF_overlay"], index_col=0)

#make variable for column names for aseg.stats data that need to be extracted
volmeasures=['Measure:volume','BrainSegVol', 'BrainSegVolNotVent',
             'CortexVol','TotalGrayVol','EstimatedTotalIntraCranialVol',
             'Left-Amygdala','Right-Amygdala']

#import the aseg.stats data for the old (FS) thalamus segmentation (stored in SUBJECTS_DIR)
asegstat_allppn=pd.read_csv(os.path.join(outputdir,asegallstatsfile),
                            delimiter='\t', index_col=0, usecols=volmeasures)

#Make empty dataframe for the master dataframe
df_master = pd.DataFrame()

#for loop that will add volume data (indexed from volume_nucleigroups.csv in stats dir) to
# dataframes for every subject
for subj in subjdirs:
    print(subj)
    os.chdir(os.path.join(workdir,subj,'stats'))

    #import the data for the volumes of the nucleigroups, index is nucleigroup
    # transpose the dataframe and append to df_master
    df_master = df_master.append(pd.read_csv(subj + '_amyg_volume_nucleigroups.csv', delimiter = ',',
                         index_col = 'nucleigroup').T, ignore_index=True)


#set subject ID column as index for the master_df
df_master['subject_ID'] = subjdirs
df_master = df_master.reset_index(drop=True)
df_master = df_master.set_index('subject_ID')

#add column with WM overlap column to master dataframe
df_master = df_master.merge(df_WM, left_index=True, right_index=True)

#add column with CSF overlap column to master dataframe
df_master = df_master.merge(df_CSF, left_index=True, right_index=True)

#select columns of interest from asegstat file (left old, Right old and intracranial volume)
df_LT_RT_ICV = pd.DataFrame(asegstat_allppn.loc[:,["Left-Amygdala","Right-Amygdala",
                                                   "EstimatedTotalIntraCranialVol"]])

#set index title to subject ID and rename Old thalamus column names
df_LT_RT_ICV.index.name = "subject_ID"
df_LT_RT_ICV.columns=["Old_Left-Amyg", "Old_Right-Amyg", "ICV"]

#Add old thalamus (Left, Right, ICV) data to master dataframe
df_master = df_master.merge(df_LT_RT_ICV, left_index=True, right_index=True)

#Calculate difference Old thalami (FS) and New thalami (Iglesias) and add as column
df_master["diff_Right-Amyg"]=df_master["Old_Right-Amyg"]-df_master["whole_amygdala_rh"]
df_master["diff_Left-Amyg"]=df_master["Old_Left-Amyg"]-df_master["whole_amygdala_lh"]

# round volume to 3 decimals
df_master=df_master.round(3)

#Save master dataframe to csv
df_master.to_csv(os.path.join(outputdir,(outbase + '_amygdala_vols.csv')), na_rep='NULL')

# for debugging
# load df_master
#os.chdir('D:/surfdrive/VUmc_eigen_projecten')
#df_master=pd.read_csv('df_master_CV.csv',index_col='subject_ID')

#####################
# OUTLIER DETECTION #
#####################

# Make copy of master_df, cal this df_master_outliers and make list of its column headers
df_master_outliers = df_master.copy()

if 'group' in df_master_outliers:
    del df_master_outliers['group']

if 'ICV' in df_master_outliers:
    del df_master_outliers['ICV']

# correct for ICV
df_master_outliers=df_master_outliers.divide(df_master['ICV'], axis = 'rows').multiply(1000000)


# write for loop for all columns in the master_df
for i in df_master_outliers.columns:

   lijst = np.array(df_master_outliers[i])
   q1_x = np.quantile(lijst, 0.25, interpolation='midpoint')
   q3_x = np.quantile(lijst, 0.75, interpolation='midpoint')
   IQR = q3_x - q1_x
   outlier_low = q1_x - (IQR* 1.5)
   outlier_high= q3_x + (IQR* 1.5)

   df_master_outliers[i+"-out"]=0
   df_master_outliers.loc[df_master_outliers[i] > outlier_high, i+'-out'] = 1
   df_master_outliers.loc[df_master_outliers[i] < outlier_low, i+'-out'] = 1

#Save df_master_outliers dataframe to csv
df_master_outliers=df_master_outliers.filter(regex='-out')
print('number of detected outliers:')
print(df_master_outliers.sum())

df_master_outliers.to_csv(os.path.join(outputdir,(outbase + '_amyg_outliers.csv')), na_rep='NULL')


#######################
# OUTLIERS 2 TXT file #
#######################
print('saving subject IDs to outliers.txt in output directory')


def getIndexes(dfObj, value):
    ''' Get index positions of value in dataframe i.e. dfObj.'''
    listOfPos = list()
    # Get bool dataframe with True at positions where the given value exists
    result = dfObj.isin([value])
    # Get list of columns that contains the value
    seriesObj = result.any()
    columnNames = list(seriesObj[seriesObj == True].index)
    # Iterate over list of columns and fetch the rows indexes where value exists
    for col in columnNames:
        rows = list(result[col][result[col] == True].index)
        for row in rows:
            listOfPos.append((row))
    # Return a list of tuples indicating the positions of value in the dataframe
    return listOfPos

idxoutliers=np.unique(getIndexes(df_master_outliers,1))
outliersdf=pd.DataFrame(idxoutliers,index=None)
outliersdf.to_csv(os.path.join(workdir,'amyg_outliers.txt'),header=False,index=False, sep=' ')


#####################
#  CORRECT FOR ICV  #
#####################

filter_lh = [col for col in df_master if col.endswith('_lh')]
filter_rh = [col for col in df_master if col.endswith('_rh')]

# divide all values by ICV and multiply by 1000000
df_master2=df_master.loc[:,filter_lh + filter_rh].divide(df_master['ICV'], axis = 'rows').multiply(1000000)



#####################
#  PREPARE 4 RAIN   #
#####################

# take ICV corrected dataframe

df_sub = pd.DataFrame()

for c in df_master2.columns:
    if 'whole' not in c:
        temp=pd.DataFrame(columns = ['volume', 'nucleigroup'])
        temp=df_master2[[c]].rename(columns={c : 'volume'})
        temp['nucleigroup']=pd.Series(c, index=df_master2.index)

        df_sub=df_sub.append(temp)

        del temp

### old code ###

# df_left=df_master.filter(regex='_lh')
# df_right=df_master.filter(regex='_rh')


# # for loops below are using ICV corrected values

# df_sub_lh = pd.DataFrame()
# df_sub_rh = pd.DataFrame()

# for c in filter_lh:

#     if 'whole' not in c:
#         temp=pd.DataFrame(columns = ['volume', 'nucleigroup'])
#         temp=df_master2[[c]].rename(columns={c : 'volume'})
#         temp['nucleigroup']=pd.Series(c, index=df_master2.index)

#         df_sub_lh=df_sub_lh.append(temp)

#         del temp

# for c in filter_rh:

#       if 'whole' not in c:
#         temp=pd.DataFrame(columns = ['volume', 'nucleigroup'])
#         temp=df_master2[[c]].rename(columns={c : 'volume'})
#         temp['nucleigroup']=pd.Series(c, index=df_master2.index)
#         df_sub_rh=df_sub_rh.append(temp)


# # split into basolateral, centromedial and cortical-like

# df1_lh, df2_lh, df3_lh = [x for _, x in df_sub_lh.groupby(df_sub_lh['nucleigroup'])]
# df1_rh, df2_rh, df3_rh = [x for _, x in df_sub_rh.groupby(df_sub_rh['nucleigroup'])]

# # merge left and right

# df1=df1_lh.append(df1_rh).round(2)
# df2=df2_lh.append(df2_rh).round(2)
# df3=df3_lh.append(df3_rh).round(2)

# dflists=[df1, df2, df3]

#########################
#  INTERACTIVE PLOTS    #
#########################

# old code

# # plots of individual nuclei
# for l in range(len(dflists)):

#     dfplot=dflists[l]
#     labels=dfplot.index.str.slice(4).astype(str).tolist()
#     fig = px.violin(dfplot,x='nucleigroup',y='volume',points="all",
#                    hover_name=labels,box=True,hover_data=dfplot.columns,color='nucleigroup',
#                    title='volume of amygdala subnuclei (corrected for ICV)')
#     fig.update_layout(uniformtext_minsize=14, uniformtext_mode='hide')

#     plotname=dfplot['nucleigroup'].unique()[0][:-3]
#     fig.write_html(os.path.join(outputdir,(plotbase + '_' + 'amyg_vol_' + plotname + '.html')))

### END OLD CODE ###


fig = make_subplots(rows=2, cols=3)
labels=df_sub.index.str.slice(4).astype(str).tolist()
fig1= px.violin(df_sub,x='nucleigroup',y='volume',points="all",
               hover_name=labels,box=True,hover_data=df_sub.columns,color='nucleigroup',
                   title='')
fig1.update_layout(uniformtext_minsize=14, uniformtext_mode='hide')

fig.append_trace(fig1.data[0],1,1)
fig.append_trace(fig1.data[1],1,2)
fig.append_trace(fig1.data[2],1,3)
fig.append_trace(fig1.data[3],2,1)
fig.append_trace(fig1.data[4],2,2)
fig.append_trace(fig1.data[5],2,3)

fig.write_html(os.path.join(outputdir,(plotbase + '_' + 'amygdala_subnuclei.html')))



# Difference between Old and New Segmentation of thalamus
oldnewdiff=df_master.filter(['diff_Right-Amyg','diff_Left-Amyg']).reset_index().melt(var_name='region',
                                                                                     value_name='volume_difference',id_vars=['subject_ID']).set_index('subject_ID').round(3)

labels=oldnewdiff.index.str.slice(4).astype(str).tolist()
xticklabels=['left amygdala difference', 'right amygdala difference']
fig= px.violin(oldnewdiff,x='region',y='volume_difference',points="all",
               hover_name=labels,box=True,hover_data=oldnewdiff.columns,color='region',
                   title='difference in volume between DK standard and Iglesias segmentation of amygdala (uncorrected for ICV)')
fig.update_layout(uniformtext_minsize=14, uniformtext_mode='hide')
fig.write_html(os.path.join(outputdir,(plotbase + '_' + 'Amyg_vol_diff_DKvsIgl.html')))

# overlap WM and CSF
overlapWMCSF=df_master.filter(['WM_overlay','CSF_overlay']).reset_index().melt(var_name='compartment',value_name='num_voxels',id_vars=['subject_ID']).set_index('subject_ID')

labels=overlapWMCSF.index.str.slice(4).astype(str).tolist()

fig = make_subplots(rows=1, cols=2)


fig1= px.violin(overlapWMCSF,x='compartment',y='num_voxels',points="all",
               hover_name=labels,box=True,hover_data=overlapWMCSF.columns,color='compartment',
                   title='Overlap of Iglesias amygdala segmentation with WM and CSF')
fig1.update_layout(uniformtext_minsize=14, uniformtext_mode='hide')

fig.append_trace(fig1.data[0],1,1)
fig.append_trace(fig1.data[1],1,2)

fig.write_html(os.path.join(outputdir,(plotbase + '_' + 'Amyg_vol_overlap_WMCSF.html')))



#########################
#  HERE COMES THE RAIN  #
#########################

df1, df2, df3,df4,df5,df6 = [x for _, x in df_sub.groupby(df_sub['nucleigroup'])]
dfs=[df1,df2,df3,df4,df5,df6]

dy='volume'
dx='nucleigroup'
ort="v";
pal = sns.color_palette(n_colors=3)
sigma = .3
fig, axes = plt.subplots(ncols=3,nrows=2,figsize=(23.38, 8.27,))
fig.suptitle('volume of amygdala subnuclei (corrected for ICV)')


for i, ax in zip(range(len(dfs)), axes.flat):

    data=dfs[i]
    ax_al=pt.RainCloud(x = dx, y = dy,
                    data = data, palette = pal,
                    bw = sigma,width_viol = .3, orient = ort,ax=ax)
    ax.set_title('')
    ax.set_ylabel('mm³')
    ax.set_xlabel('')
    #plt.setp(ax.get_xticklabels(), rotation=0, ha="right", rotation_mode="anchor")

plt.subplots_adjust(left=0.125, bottom=0.1, right=0.9, top=0.9, wspace=0.4, hspace=0.2)


plt.savefig(os.path.join(outputdir,(plotbase + '_' + 'vol_amygsubnuclei.pdf')), bbox_inches='tight', format='pdf')
plt.savefig(os.path.join(outputdir,(plotbase + '_' + 'vol_amygsubnuclei.png')), dpi=150,bbox_inches='tight', format='png')
