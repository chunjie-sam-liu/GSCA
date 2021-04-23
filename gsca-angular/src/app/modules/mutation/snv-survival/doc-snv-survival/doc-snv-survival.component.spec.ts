import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { DocSnvSurvivalComponent } from './doc-snv-survival.component';

describe('DocSnvSurvivalComponent', () => {
  let component: DocSnvSurvivalComponent;
  let fixture: ComponentFixture<DocSnvSurvivalComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ DocSnvSurvivalComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(DocSnvSurvivalComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
