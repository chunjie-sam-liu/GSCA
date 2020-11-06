import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { MutationComponent } from './mutation.component';

const routes: Routes = [
  {
    path: '',
    component: MutationComponent,
  },
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule],
})
export class MutationRoutingModule {}
