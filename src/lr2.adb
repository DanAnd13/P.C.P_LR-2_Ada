with Ada.Text_IO; use Ada.Text_IO;
with ada.numerics.discrete_random;

procedure lr2 is

   dim : constant Integer := 100000;
   thread_num : constant Integer := 3;
   id : Integer;
   arr : array(1..dim) of Integer;

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
         arr(i) := dim - i;
      end loop;
      arr(randomN) := -1;
   end Init_Arr;

   function part_min(start_index, finish_index : in Integer; id : out Integer) return Integer is
      min : Integer := arr(start_index);
   begin
      id := start_index;
      for i in start_index..finish_index loop
         if min > arr(i) then
            min := arr(i);
            id := i;
         end if;
      end loop;
      return min;
   end part_min;

   task type starter_thread is
      entry start(start_index, finish_index : in Integer);
   end starter_thread;

   protected part_manager is
      procedure set_part_min(min : in Integer; id : in Integer);
      entry get_min(min : out Integer; id : out Integer);
   private
      tasks_count : Integer := 0;
      minimum : Integer := dim;
      min_id : Integer := 1;
   end part_manager;

   protected body part_manager is
      procedure set_part_min(min : in Integer; id : in Integer) is
      begin
         if minimum > min then
            minimum := min;
            min_id := id;
         end if;
         tasks_count := tasks_count + 1;
      end set_part_min;

      entry get_min(min : out Integer; id : out Integer) when tasks_count = thread_num is
      begin
         min := minimum;
         id := min_id;
      end get_min;

   end part_manager;

   task body starter_thread is
      min : Integer := 0;
      start_index, finish_index : Integer;
      id : Integer := 0;
   begin
      accept start(start_index, finish_index : in Integer) do
         starter_thread.start_index := start_index;
         starter_thread.finish_index := finish_index;
      end start;
      min := part_min(start_index, finish_index, id);
      part_manager.set_part_min(min, id);
   end starter_thread;

   function parallel_min return Integer is
      part_size : Integer := dim / thread_num;
      start_index, end_index : Integer;
      min : Integer := 0;
      id : Integer := 0;
      thread : array(1..thread_num) of starter_thread;
   begin
      for i in 1..thread_num loop
         start_index := (i - 1) * part_size;
         if i = thread_num then
            end_index := dim;
         else
            end_index := i * part_size;
         end if;
         thread(i).start(start_index + 1, end_index);
      end loop;
      part_manager.get_min(min, id);
      return min;
   end parallel_min;

begin
   Init_Arr;
   Put_Line("Min elem " & Integer'Image(part_min(1, dim, id)) & " with id " & id'Img);
   Put_Line("Min elem " & Integer'Image(parallel_min) & " with id " & id'Img);
end lr2;
