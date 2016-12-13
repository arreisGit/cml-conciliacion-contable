CREATE NONCLUSTERED INDEX [IX_DineroD_Aplica_AplicaID]
ON [dbo].[DineroD] ([Aplica],[AplicaID])
INCLUDE ([ID],[Importe],[FormaPago])