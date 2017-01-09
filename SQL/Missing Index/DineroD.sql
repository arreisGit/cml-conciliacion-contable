IF NOT EXISTS(SELECT 
                * 
              FROM
                sys.indexes
              WHERE
                name = 'IX_DineroD_Aplica_AplicaID'
              AND object_id = OBJECT_ID('DineroD'))
BEGIN
      
  CREATE NONCLUSTERED INDEX [IX_DineroD_Aplica_AplicaID]
  ON [dbo].[DineroD] ([Aplica],[AplicaID])
  INCLUDE ([ID],[Importe],[FormaPago])
  
END
