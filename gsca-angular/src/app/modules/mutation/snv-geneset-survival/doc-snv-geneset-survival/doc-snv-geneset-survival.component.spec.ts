import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { DocSnvGenesetSurvivalComponent } from './doc-snv-geneset-survival.component';

describe('DocSnvGenesetSurvivalComponent', () => {
  let component: DocSnvGenesetSurvivalComponent;
  let fixture: ComponentFixture<DocSnvGenesetSurvivalComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ DocSnvGenesetSurvivalComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(DocSnvGenesetSurvivalComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
