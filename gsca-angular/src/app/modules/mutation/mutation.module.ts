import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';

import { MutationRoutingModule } from './mutation-routing.module';
import { MutationComponent } from './mutation.component';
import { SharedModule } from 'src/app/shared/shared.module';
import { SearchBoxComponent } from './search-box/search-box.component';
import { SnvComponent } from './snv/snv.component';
import { SnvSurvivalComponent } from './snv-survival/snv-survival.component';

@NgModule({
  declarations: [MutationComponent, SearchBoxComponent, SnvComponent, SnvSurvivalComponent],
  imports: [CommonModule, MutationRoutingModule, SharedModule],
})
export class MutationModule {}
