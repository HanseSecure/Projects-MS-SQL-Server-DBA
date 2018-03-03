﻿






	CREATE view [inf].[vRequests] as
/*
	ГЕМ: Сведения о запросах
*/
SELECT session_id
	  ,status
	  ,blocking_session_id
	  ,database_id
	  ,DB_NAME(database_id) as DBName
	  ,(select top(1) text from sys.dm_exec_sql_text([sql_handle])) as [TSQL]
	  ,(select top(1) [query_plan] from sys.dm_exec_query_plan([plan_handle])) as [QueryPlan]
	  ,[sql_handle]
      ,[statement_start_offset]--Количество символов в выполняемом в настоящий момент пакете или хранимой процедуре, в которой запущена текущая инструкция. Может применяться вместе с функциями динамического управления sql_handle, statement_end_offset и sys.dm_exec_sql_text для получения исполняемой в настоящий момент инструкции для запроса. Допускаются значения NULL.
      ,[statement_end_offset]--Количество символов в выполняемом в настоящий момент пакете или хранимой процедуре, в которой завершилась текущая инструкция. Может применяться вместе с функциями динамического управления sql_handle, statement_end_offset и sys.dm_exec_sql_text для получения исполняемой в настоящий момент инструкции для запроса. Допускаются значения NULL.
      ,[plan_handle]
      ,[user_id]
      ,[connection_id]
      ,[wait_type]--тип ожидания
      ,[wait_time]--Если запрос в настоящий момент блокирован, в столбце содержится продолжительность текущего ожидания (в миллисекундах). Не допускает значение NULL.
	  ,round(cast([wait_time] as decimal(18,3))/1000, 3) as [wait_timeSec]
      ,[last_wait_type]--Если запрос был блокирован ранее, в столбце содержится тип последнего ожидания. Не допускает значение NULL.
      ,[wait_resource]--Если запрос в настоящий момент блокирован, в столбце указан ресурс, освобождения которого ожидает запрос. Не допускает значение NULL.
      ,[open_transaction_count]--Число транзакций, открытых для данного запроса. Не допускает значение NULL.
      ,[open_resultset_count]--Число результирующих наборов, открытых для данного запроса. Не допускает значение NULL.
      ,[transaction_id]--Идентификатор транзакции, в которой выполняется запрос. Не допускает значение NULL.
      ,[context_info]
      ,[percent_complete]
      ,[estimated_completion_time]
      ,[cpu_time]--Время ЦП (в миллисекундах), затраченное на выполнение запроса. Не допускает значение NULL.
	  ,round(cast([cpu_time] as decimal(18,3))/1000, 3) as [cpu_timeSec]
      ,[total_elapsed_time]--Общее время, истекшее с момента поступления запроса (в миллисекундах). Не допускает значение NULL.
	  ,round(cast([total_elapsed_time] as decimal(18,3))/1000, 3) as [total_elapsed_timeSec]
      ,[scheduler_id]--Идентификатор планировщика, который планирует данный запрос. Не допускает значение NULL.
      ,[task_address]--Адрес блока памяти, выделенного для задачи, связанной с этим запросом. Допускаются значения NULL.
      ,[reads]--Число операций чтения, выполненных данным запросом. Не допускает значение NULL.
      ,[writes]--Число операций записи, выполненных данным запросом. Не допускает значение NULL.
      ,[logical_reads]--Число логических операций чтения, выполненных данным запросом. Не допускает значение NULL.
      ,[text_size]--Установка параметра TEXTSIZE для данного запроса. Не допускает значение NULL.
      ,[language]--Установка языка для данного запроса. Допускаются значения NULL.
      ,[date_format]--Установка параметра DATEFORMAT для данного запроса. Допускаются значения NULL.
      ,[date_first]--Установка параметра DATEFIRST для данного запроса. Не допускает значение NULL.
      ,[quoted_identifier]
      ,[arithabort]
      ,[ansi_null_dflt_on]
      ,[ansi_defaults]
      ,[ansi_warnings]
      ,[ansi_padding]
      ,[ansi_nulls]
      ,[concat_null_yields_null]
      ,[transaction_isolation_level]--Уровень изоляции, с которым создана транзакция для данного запроса. Не допускает значение NULL (0-не задан, от 1 до 5 поувеличению уровня изоляции транзакции)
      ,[lock_timeout]--Время ожидания блокировки для данного запроса (в миллисекундах). Не допускает значение NULL.
      ,[deadlock_priority]--Значение параметра DEADLOCK_PRIORITY для данного запроса. Не допускает значение NULL.
      ,[row_count]--Число строк, возвращенных клиенту по данному запросу. Не допускает значение NULL.
      ,[prev_error]--Последняя ошибка, происшедшая при выполнении запроса. Не допускает значение NULL.
      ,[nest_level]--Текущий уровень вложенности кода, выполняемого для данного запроса. Не допускает значение NULL.
      ,[granted_query_memory]--Число страниц, выделенных для выполнения поступившего запроса. Не допускает значение NULL.
      ,[executing_managed_code]--Указывает, выполняет ли данный запрос в настоящее время код объекта среды CLR (например, процедуры, типа или триггера). Этот флаг установлен в течение всего времени, когда объект среды CLR находится в стеке, даже когда из среды вызывается код Transact-SQL. Не допускает значение NULL.
      ,[group_id]--Идентификатор группы рабочей нагрузки, которой принадлежит этот запрос. Не допускает значение NULL.
      ,[query_hash]--Двоичное хэш-значение рассчитывается для запроса и используется для идентификации запросов с аналогичной логикой. Можно использовать хэш запроса для определения использования статистических ресурсов для запросов, которые отличаются только своими литеральными значениями.
      ,[query_plan_hash]--Двоичное хэш-значение рассчитывается для плана выполнения запроса и используется для идентификации аналогичных планов выполнения запросов. Можно использовать хэш плана запроса для нахождения совокупной стоимости запросов со схожими планами выполнения.
FROM sys.dm_exec_requests







GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Сведения о запросах экземпляра MS SQL Server', @level0type = N'SCHEMA', @level0name = N'inf', @level1type = N'VIEW', @level1name = N'vRequests';

