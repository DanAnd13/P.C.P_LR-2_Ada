with Ada.Text_IO; use Ada.Text_IO;
with ada.numerics.discrete_random;
procedure lr2 is

   dim : constant integer := 100000;
   thread_num : constant integer := 2;
   id : Integer;
   arr : array(1..dim) of integer;

   function randomN return Integer is
      type randRange is new Integer range 1..dim;
      package Rand_Int is new ada.numerics.discrete_random(randRange);
      use Rand_Int;
      gen : Generator;
      num : randRange;
   begin
      reset(gen);
      num := random(gen);
   return Integer(num);
   end randomN;

   procedure Init_Arr is
   begin

      for i in 1..dim loop
         arr(i) := i;
      end loop;
      arr(randomN) := -1;
   end Init_Arr;

   function part_min(start_index, finish_index : in integer) return long_long_integer is
      min : long_long_integer := long_long_integer(dim + 1);
   begin
      for i in start_index..finish_index loop
         if min > Long_Long_Integer(arr(i)) then
            min := Long_Long_Integer(arr(i));
            id := i;
         end if;
      end loop;
      return min;
   end part_min;

   task type starter_thread is
      entry start(start_index, finish_index : in Integer);
   end starter_thread;

   protected part_manager is
      procedure set_part_min(min : in Long_Long_Integer);
      entry get_min(min : out Long_Long_Integer);
   private
      tasks_count : Integer := 0;
      minimum : Long_Long_Integer := long_long_integer(dim + 1);
   end part_manager;

   protected body part_manager is
      procedure set_part_min(min : in Long_Long_Integer) is
      begin
         if minimum > min then
            minimum := min;
         end if;
            tasks_count := tasks_count + 1;
      end set_part_min;

      entry get_min(min : out Long_Long_Integer) when tasks_count = thread_num is
      begin
         min := minimum;
      end get_min;

   end part_manager;

   task body starter_thread is
      min : Long_Long_Integer := 0;
      start_index, finish_index : Integer;
   begin
      accept start(start_index, finish_index : in Integer) do
         starter_thread.start_index := start_index;
         starter_thread.finish_index := finish_index;
      end start;
      min := part_min(start_index,finish_index);
      part_manager.set_part_min(min);
   end starter_thread;

   function parallel_min return Long_Long_Integer is
      part_size : Integer := dim / thread_num;
      start_index, end_index : Integer;
      min : long_long_integer := 0;
      thread : array(1..thread_num) of starter_thread;
   begin
      for i in 1..thread_num loop
         start_index := (i - 1) * part_size;
         if i = thread_num then
            end_index := dim;
         else end_index := i * part_size;
         end if;
         thread(i).start(start_index + 1, end_index);
         end loop;
      part_manager.get_min(min);
      return min;
   end parallel_min;

begin
   Init_Arr;
   Put_Line("Min elem " & (part_min(1, dim)'img) & " with id " & id'img);
   Put_Line("Min elem " & (parallel_min'img) & " with id " & id'img);
end lr2;
