create database healthcare_analysis;
use healthcare_analysis;

create table patients (
PatientID INT PRIMARY KEY,
PatientName Varchar(100),
Gender varchar(100),
Age INT,
RegistrationDate Date );

create table Appointments (
AppointmentID INT PRIMARY KEY,
PatientID INT,
AppointmentDate Date,
Department Varchar(100),
DoctorID INT,
Status Varchar(20),
foreign key ( patientID )
References Patients (patientID));

select * from patients;
select * from appointments;
--- Perform data-quality checks 
--- Check duplicate patients 

select patientID , count(*) as Count_of_Duplicate_Records
from patients
group by patientID
having count(*) > 1;

--- Check missing values 

select * from patients
where patientID is Null
or Patientname is null
or Gender is null
or Age is null
or RegistrationDate is null;

--- Check appointment statuses 
Select distinct status 
from appointments;
select * from patients;

--- Check invalid ages 

select * from patients 
where age <0 or age > 120;
-- Check there if any appointment record exists which is having no record of patient in patients table

select * from patients p
left join appointments a
on a.patientID = p.patientID
where p.patientID is null;

-- No any such record exists , therefore we are ready for the analysis.
select * from patients;
select * from appointments;
--- 1. Total Unique patients 
select count(distinct patientname) as Number_of_Patients from patients;
--- 1. Total unique Appointments
select count(distinct appointmentid) as Number_of_Appointments from appointments;

--- 2. Gender wise distribution of patients
select gender, count(*) as Count_of_Patients
from patients
group by gender;

--- 3. Average Age of patients by Gender
select gender,round(avg(age)) as Avg_Age_of_Patients
from patients
group by gender;

--- 4.  Monthly trend of appointments
select * from appointments;

select DATE_FORMAT(appointmentdate,'%M-%Y') as Month_and_Year, count(*) as Count_of_Appointments
from appointments
group by 1
order by 1;

 ----------
 --- 5. Top 3 departments with the highest number of missed appointments. 
 

 with CTE as (select department , status from appointments
 where status = 'missed'),
 
 CTE2 as (select department , count(status ) as No_of_Missed_Appointments  from CTE 
 group by department
 order by count(status) desc
 limit 3 )
 
 select department , No_of_missed_appointments ,
 rank() over ( order by No_of_missed_appointments desc) as Rank_of_Missed_Appointments
 from CTE2;
 
 --------- Another Way
 SELECT 
Department, 
COUNT(*) AS MissedAppointments 
FROM appointments 
WHERE Status = 'Missed' 
GROUP BY Department 
ORDER BY MissedAppointments DESC 
LIMIT 3; 

----------
--- 6. Distribution of appointment statuses (Completed, Missed, Cancelled). 

select status , count(*) as Count_of_Statuses from appointments
group by status;

---- 
--- 7. Repeat patient rate: Number of patients with more than one appointment.
--- Using CTES

with Repeating_patients_No as (select patientId , count(patientID) as Repeating_Numbers from appointments
group by patientID
having Repeating_Numbers > 1 ),

Unique_patient_No as (select count( distinct PatientID ) as No_of_Unique_Patients from appointments)

select count(*)/( select * from unique_patient_No)*100 as Repeat_Patient_Rate from Repeating_patients_No;

 -- using Subquery
 
 SELECT 
    COUNT(*) * 100.0 / (
        SELECT COUNT(DISTINCT PatientID)
        FROM appointments
    ) AS Repeat_Patient_Rate
FROM (
    SELECT PatientID
    FROM appointments
    GROUP BY PatientID
    HAVING COUNT(*) > 1
) AS RepeatPatients;
select * from appointments;
 --- 8.Average appointments per doctor per department. 
select department , count(*) as No_of_Appointments ,
count(distinct doctorID ) as No_of_Doctors , count(*)/ count(distinct doctorID) as Avg_Appointments
from appointments
group by department 
order by avg_appointments desc ;

-------
--- 9. . Patients with more than 2 missed appointments.  
select * from patients;
select * from appointments;
select p.patientid , p.patientName , count(a.appointmentid) as Count_of_Appointments from patients p
inner join appointments a 
on p.patientid = a.patientid
where status = 'missed'
group by 1,2
having Count_of_Appointments >2
order by 3 desc;

-----
use healthcare_analysis;
select * from appointments;
select * from patients;

---- 10. Use a CTE to find patients who registered in 2020 and calculate their average 
--- appointment gap (days between appointments)

with CTE as (select patientid , patientname from patients
where year(Registrationdate) = '2020' ),

CTE2 as (select c.patientname , a.appointmentdate from CTE c
inner join appointments a
on c.patientid = a.patientid
order by c.patientname asc ),

CTE3 as (select patientname , appointmentdate ,
lag(appointmentdate) over ( partition by patientname ORDER BY APPOINTMENTDATE ) as Previous_App_date
from CTE2 ),


CTE4 as (select patientname , appointmentdate ,PREVIOUS_APP_DATE , datediff(appointmentdate , previous_app_date) as Diff_of_App
from CTE3)

select patientname,avg(Diff_of_App) as Avg_Appointment_Gap from CTE4
group by 1;

---- 11. For each patient, rank their appointments by date and flag their first visit.  

 with Ranked_Visits as (select patientid , appointmentdate , 
 rank() over(partition by patientid order by appointmentdate ) as Rank_of_Visits
 from appointments )
 
 select patientid,appointmentdate, rank_of_visits,
 case 
 when Rank_of_Visits = 1 then 'First_Visit'
 else null
 end as Flag_Visits
 from Ranked_visits;
 ----------
 select * from appointments;
 --- 12.  Find department-wise monthly no-show rates. 
 
select department , year(appointmentdate),month(appointmentdate),
count(
case 
when status = 'missed' then 1
end)*100/count(*) as No_Show_Rate
from appointments
group by 1,2,3
order by 1,2 desc;



