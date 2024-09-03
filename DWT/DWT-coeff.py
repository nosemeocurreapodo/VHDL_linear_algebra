
# coding: utf-8

# In[3]:


get_ipython().system('pip install mne')


# In[7]:


get_ipython().system('pip install PyWavelets')


# In[4]:


import mne


# In[6]:


import numpy as np
import pandas as pd


# In[8]:


import pywt


# In[9]:


from pywt import wavedec


# In[10]:


raw = mne.io.read_raw_edf("1-2.edf", preload=True)


# In[11]:


raw.info


# In[12]:


# Sélectionner les 5 premiers canaux EEG
#r=raw.pick_channels(raw.ch_names[:5])


# In[20]:


print(r.info)


# In[21]:


r.plot()


# In[24]:


get_ipython().run_cell_magic('time', '', 'rf = r.filter(0.1,30)')


# In[25]:


rf.plot()


# In[26]:


print(rf.info)


# In[30]:


selected_channel_name = rf.info['ch_names']
sample_frequency = rf.info['sfreq']
epoch_duration = 10


# In[28]:


selected_channel_name


# In[31]:


sample_frequency


# In[32]:


epoch_samples = int(epoch_duration*sample_frequency)


# In[33]:


epoch_samples


# In[35]:


total_epochs = 307200// epoch_samples


# In[36]:


total_epochs


# In[37]:


epochs_matrix = np.zeros((total_epochs, 5, epoch_samples))  # 5 channels


# In[41]:


# Segmenter les données en epochs de 10 secondes
events = mne.make_fixed_length_events(rf, duration=epoch_duration)


# In[42]:


# Créer un objet Epochs
epochs = mne.Epochs(rf, events, tmin=0, tmax=epoch_duration, baseline=None, detrend=1)


# In[43]:


# Obtenir les données des epochs sous forme de tableau numpy
epochs_data = epochs.get_data()


# In[44]:


# Vérifier la forme de la matrice d'epochs
print("Forme de la matrice d'epochs:", epochs_data.shape)


# In[47]:


get_ipython().system('pip install scipy')


# In[48]:


import scipy.stats as stats


# In[49]:


zscores = stats.zscore(epochs_data)


# In[50]:


zscores.shape


# In[51]:


# Définition de la famille d'ondelettes à utiliser
wavelet = 'db4'

# Initialisation des tableaux pour stocker les caractéristiques
cD_Energy = np.zeros((59, 5))
cA_Energy = np.zeros((59, 5))
D_Entropy = np.zeros((59, 5))
A_Entropy = np.zeros((59, 5))
D_mean = np.zeros((59, 5))
A_mean = np.zeros((59, 5))
D_std = np.zeros((59, 5))
A_std = np.zeros((59, 5))


# In[56]:


get_ipython().run_cell_magic('time', '', 'for i in range(59):\n  for j in range(5):\n    coeffs = pywt.wavedec(zscores[i, j, :], wavelet)  # Calcul de la DWT avec pywt\n    cD_Energy[i,j] = np.mean([np.sum(np.square(coeffs[5])),np.sum(np.square(coeffs[4])),\n                         np.sum(np.square(coeffs[3])),np.sum(np.square(coeffs[2])),\n                         np.sum(np.square(coeffs[1]))])\n    cA_Energy[i,j] = np.sum(np.square(coeffs[0]))\n    D_Entropy[i,j] = np.mean([np.sum(np.square(coeffs[5]) * np.log(np.square(coeffs[5]))),\n                         np.sum(np.square(coeffs[4]) * np.log(np.square(coeffs[4]))),\n                         np.sum(np.square(coeffs[3]) * np.log(np.square(coeffs[3]))),\n                         np.sum(np.square(coeffs[2]) * np.log(np.square(coeffs[2]))),\n                         np.sum(np.square(coeffs[1]) * np.log(np.square(coeffs[1])))])\n    A_Entropy[i,j] = np.sum(np.square(coeffs[0]) * np.log(np.square(coeffs[0])))\n    D_mean[i,j] = np.mean([np.mean(coeffs[5]),np.mean(coeffs[4]),np.mean(coeffs[3]),np.mean(coeffs[2]),np.mean(coeffs[1])])\n    A_mean[i,j] = np.mean(coeffs[0])\n    D_std[i,j] = np.mean([np.std(coeffs[5]),np.std(coeffs[4]),np.std(coeffs[3]),np.std(coeffs[2]),np.std(coeffs[1])])\n    A_std[i,j] = np.std(coeffs[0])')


# In[53]:


df = pd.DataFrame(cD_Energy)
df1 = pd.DataFrame(cA_Energy)
df2 = pd.DataFrame(D_Entropy)
df3 = pd.DataFrame(A_Entropy)
df4 = pd.DataFrame(D_mean)
df5 = pd.DataFrame(A_mean)
df6 = pd.DataFrame(D_std)
df7 = pd.DataFrame(A_std)


# In[54]:


ddd = pd.concat([df,df1,df2,df3,df4,df5,df6,df7], axis = 1)


# In[55]:


ddd

